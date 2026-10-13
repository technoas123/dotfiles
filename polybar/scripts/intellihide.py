#!/usr/bin/env python3

import time
import sys
import signal
import os
import threading
from Xlib import display, X

# ==========================================
# CONFIGURATION
# ==========================================
PERIMETER = 8
VISIBLE_EDGE = 1
PEEK_THRESHOLD = 12
PEEK_DELAY = 0.45
PEEK_GRACE_AREA = 20
POLL_RATE = 0.1
FPS = 60
ANIMATION_SMOOTHNESS = 0.15
# ==========================================

class IntelligentPolybarHider:
    def __init__(self):
        try:
            self.d = display.Display()
            self.d.set_error_handler(self.silent_error_handler)
        except Exception:
            print("Could not connect to X display.")
            sys.exit(1)
            
        self.root = self.d.screen().root
        self.setup_atoms()
        
        self.bars = self.find_polybars()
        if not self.bars:
            print("No Polybar instances found. Ensure Polybar is running.")
            sys.exit(1)
            
        self.running = True
        self.last_collision_state = False

        # Collision results are produced by a background thread (see
        # collision_worker) and consumed here under this lock, so the
        # animation loop never blocks on the X11 round-trips involved
        # in scanning every open window.
        self.collision_lock = threading.Lock()
        self.is_colliding = False
        self.is_fullscreen_active = False

        self.peek_timer = None
        self.is_actively_peeking = False
        self.mode = "AUTO" 
        
        # --- BULLETPROOF HOTKEY SETUP ---
        self.pid_file = "/tmp/polybar_hider.pid"
        with open(self.pid_file, "w") as f:
            f.write(str(os.getpid()))
            
        signal.signal(signal.SIGUSR1, self.toggle_mode)

    def silent_error_handler(self, err, request):
        pass
        
    def toggle_mode(self, signum, frame):
        modes = ["AUTO", "LOCKED_SHOW", "LOCKED_HIDE"]
        current_idx = modes.index(self.mode)
        self.mode = modes[(current_idx + 1) % len(modes)]
        print(f"\n[Manual Override] State changed to: {self.mode}")

    def setup_atoms(self):
        self.ATOM_CLIENT_LIST = self.d.get_atom('_NET_CLIENT_LIST')
        self.ATOM_WM_DESKTOP = self.d.get_atom('_NET_WM_DESKTOP')
        self.ATOM_CURRENT_DESKTOP = self.d.get_atom('_NET_CURRENT_DESKTOP')
        self.ATOM_WINDOW_TYPE = self.d.get_atom('_NET_WM_WINDOW_TYPE')
        self.ATOM_TYPE_NORMAL = self.d.get_atom('_NET_WM_WINDOW_TYPE_NORMAL')
        self.ATOM_TYPE_DIALOG = self.d.get_atom('_NET_WM_WINDOW_TYPE_DIALOG')
        self.ATOM_GTK_FRAME_EXTENTS = self.d.get_atom('_GTK_FRAME_EXTENTS')
        self.ATOM_NET_WM_STATE = self.d.get_atom('_NET_WM_STATE')
        self.ATOM_STATE_FULLSCREEN = self.d.get_atom('_NET_WM_STATE_FULLSCREEN')

    def find_polybars(self):
        bars = []
        for child in self.root.query_tree().children:
            try:
                wm_class = child.get_wm_class()
                if wm_class and 'polybar' in wm_class[0].lower():
                    geom = child.get_geometry()
                    bars.append({
                        'win': child,
                        'x': geom.x,
                        'w': geom.width,
                        'h': geom.height,
                        'visible_y': float(geom.y),
                        'hidden_y': float(-(geom.height - VISIBLE_EDGE)),
                        'current_y': float(geom.y)
                    })
            except Exception:
                continue
        return bars

    def get_extents(self, win, atom):
        try:
            prop = win.get_full_property(atom, X.AnyPropertyType)
            if prop and prop.format == 32 and hasattr(prop, 'value'):
                val = prop.value
                if len(val) >= 4:
                    return int(val[0]), int(val[1]), int(val[2]), int(val[3])
        except Exception:
            pass
        return 0, 0, 0, 0

    def get_window_bbox(self, client_win, root):
        frame = client_win
        try:
            while True:
                tree = frame.query_tree()
                parent = tree.parent
                if not parent or parent.id == root.id:
                    break
                frame = parent
                
            if frame.get_attributes().map_state != X.IsViewable:
                return None
                
            geom = frame.get_geometry()
            w_x, w_y = geom.x, geom.y
            w_w, w_h = geom.width, geom.height
            
            gtk_left, gtk_right, gtk_top, gtk_bottom = self.get_extents(client_win, self.ATOM_GTK_FRAME_EXTENTS)
            if gtk_left > 0 or gtk_right > 0 or gtk_top > 0 or gtk_bottom > 0:
                w_x += gtk_left
                w_y += gtk_top
                w_w -= (gtk_left + gtk_right)
                w_h -= (gtk_top + gtk_bottom)
                
            return w_x, w_y, w_w, w_h
        except Exception:
            return None

    def check_collisions(self, dpy, root):
        ws_prop = root.get_full_property(self.ATOM_CURRENT_DESKTOP, X.AnyPropertyType)
        current_workspace = ws_prop.value[0] if ws_prop else 0

        prop = root.get_full_property(self.ATOM_CLIENT_LIST, X.AnyPropertyType)
        if not prop:
            return False, False, None
            
        is_colliding = False
        is_fullscreen_active = False
        collider_info = None
            
        for win_id in prop.value:
            try:
                client_win = dpy.create_resource_object('window', win_id)
                
                wm_class = client_win.get_wm_class()
                win_name = wm_class[0] if wm_class else "unknown"
                if 'polybar' in win_name.lower():
                    continue

                desk_prop = client_win.get_full_property(self.ATOM_WM_DESKTOP, X.AnyPropertyType)
                if desk_prop and desk_prop.value[0] not in (current_workspace, 0xFFFFFFFF):
                    continue
                    
                state_prop = client_win.get_full_property(self.ATOM_NET_WM_STATE, X.AnyPropertyType)
                if state_prop and self.ATOM_STATE_FULLSCREEN in state_prop.value:
                    is_fullscreen_active = True

                type_prop = client_win.get_full_property(self.ATOM_WINDOW_TYPE, X.AnyPropertyType)
                if type_prop:
                    types = type_prop.value
                    if self.ATOM_TYPE_NORMAL not in types and self.ATOM_TYPE_DIALOG not in types:
                        continue

                bbox = self.get_window_bbox(client_win, root)
                if not bbox:
                    continue
                    
                w_x, w_y, w_w, w_h = bbox
                win_x2 = w_x + w_w
                win_y2 = w_y + w_h

                for bar in self.bars:
                    box_x1 = bar['x'] - PERIMETER
                    box_x2 = bar['x'] + bar['w'] + PERIMETER
                    box_y1 = bar['visible_y'] - PERIMETER
                    box_y2 = bar['visible_y'] + bar['h'] + PERIMETER

                    if (w_x < box_x2 and win_x2 > box_x1 and w_y < box_y2 and win_y2 > box_y1):
                        is_colliding = True
                        collider_info = f"{win_name} (X:{w_x}, Y:{w_y})"
                        break

            except Exception:
                continue

        return is_colliding, is_fullscreen_active, collider_info

    def collision_worker(self):
        """Runs on its own X11 connection so the (sometimes slow)
        per-window scan in check_collisions() never blocks the 60fps
        animation loop in run() — this decoupling is what fixes the
        stutter, which was previously caused by that scan running
        inline inside the same loop driving the animation."""
        thread_display = display.Display()
        thread_display.set_error_handler(self.silent_error_handler)
        thread_root = thread_display.screen().root

        while self.running:
            colliding, fullscreen, info = self.check_collisions(thread_display, thread_root)
            with self.collision_lock:
                if colliding and not self.last_collision_state:
                    print(f"[Hide Triggered] Intruder: {info}")
                elif not colliding and self.last_collision_state:
                    print("[Hide Released] Area clear.")
                self.last_collision_state = colliding
                self.is_colliding = colliding
                self.is_fullscreen_active = fullscreen
            time.sleep(POLL_RATE)

    def run(self):
        sleep_time = 1.0 / FPS

        print(f"Smart Hide Service started. [PID: {os.getpid()}]")
        print("Press Ctrl+C to exit.")

        threading.Thread(target=self.collision_worker, daemon=True).start()

        try:
            while self.running:
                now = time.time()
                pointer = self.root.query_pointer()

                with self.collision_lock:
                    is_colliding = self.is_colliding
                    is_fullscreen_active = self.is_fullscreen_active

                is_dragging = bool(pointer.mask & X.Button1Mask)
                in_peek_zone = (pointer.root_y <= PEEK_THRESHOLD) and not is_dragging
                
                is_hovering_bar = False
                for bar in self.bars:
                    if (bar['x'] <= pointer.root_x <= bar['x'] + bar['w']):
                        if (pointer.root_y <= bar['visible_y'] + bar['h'] + PEEK_GRACE_AREA):
                            is_hovering_bar = True
                            break

                if is_fullscreen_active:
                    self.is_actively_peeking = False 
                    self.peek_timer = None
                elif in_peek_zone:
                    if self.peek_timer is None:
                        self.peek_timer = now
                    elif (now - self.peek_timer) >= PEEK_DELAY:
                        self.is_actively_peeking = True
                else:
                    self.peek_timer = None
                    if not is_hovering_bar:
                        self.is_actively_peeking = False

                force_show = (self.mode == "LOCKED_SHOW")
                force_hide = (self.mode == "LOCKED_HIDE")

                needs_sync = False
                for bar in self.bars:
                    if force_show:
                        target_y = bar['visible_y']
                    elif force_hide:
                        target_y = bar['hidden_y']
                    else:
                        target_y = bar['visible_y'] if (self.is_actively_peeking or not is_colliding) else bar['hidden_y']

                    diff = target_y - bar['current_y']
                    if abs(diff) > 0.5:
                        step = diff * ANIMATION_SMOOTHNESS
                        bar['current_y'] += step
                        
                        if abs(target_y - bar['current_y']) < 1.0:
                            bar['current_y'] = target_y
                            
                        try:
                            bar['win'].configure(y=int(bar['current_y']))
                            needs_sync = True
                        except Exception:
                            pass 

                if needs_sync:
                    self.d.sync()

                time.sleep(sleep_time)

        except KeyboardInterrupt:
            self.restore()

    def restore(self):
        print("\nRestoring Polybar positions...")
        for bar in self.bars:
            try:
                bar['win'].configure(y=int(bar['visible_y']))
            except Exception:
                pass
        self.d.sync()
        
        # Clean up the PID file on exit
        if os.path.exists(self.pid_file):
            os.remove(self.pid_file)
            
        print("Done.")
        sys.exit(0)

if __name__ == '__main__':
    hider = IntelligentPolybarHider()
    hider.run()
