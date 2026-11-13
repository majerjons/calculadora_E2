"""
Corredor de testbenches Verilog (Icarus Verilog + GTKWave).
Uso: python correr_tb.py      (o doble click en correr_tb.bat)

- Elegis el testbench (*_tb.v) y lo compila y simula.
- Los archivos a compilar los saca de la linea "Correr: iverilog ..." que esta en el
  comentario del propio testbench. Si no la encuentra, usa todos los .v de la carpeta
  que no terminen en _tb.v.
- Boton para abrir el .vcd en GTKWave.
"""
import os, re, shutil, subprocess, sys, threading
import tkinter as tk
from tkinter import filedialog, scrolledtext, messagebox

WIN = os.name == "nt"
CARPETAS_WIN = [r"C:\iverilog\bin", r"C:\Program Files\iverilog\bin",
                r"C:\Program Files (x86)\iverilog\bin",
                r"C:\iverilog\gtkwave\bin", r"C:\Program Files\iverilog\gtkwave\bin"]

def buscar(exe):
    ruta = shutil.which(exe)
    if ruta:
        return ruta
    if WIN:
        for c in CARPETAS_WIN:
            p = os.path.join(c, exe + ".exe")
            if os.path.isfile(p):
                return p
    return None

def archivos_de(tb_path):
    """Lista de .v a compilar junto con el testbench."""
    carpeta = os.path.dirname(tb_path)
    tb = os.path.basename(tb_path)
    with open(tb_path, encoding="utf-8", errors="ignore") as f:
        for linea in f:
            m = re.search(r"iverilog\s+(.*)", linea) if linea.lstrip().startswith("//") else None
            if m:
                tokens = m.group(1).split()
                archivos = [t for t in tokens if t.endswith(".v")]
                if tb not in archivos:
                    archivos.insert(0, tb)
                return archivos, "linea 'Correr' del testbench"
    todos = [x for x in sorted(os.listdir(carpeta)) if x.endswith(".v") and not x.endswith("_tb.v")]
    return [tb] + todos, "todos los .v de la carpeta"

class App(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("Corredor de testbenches Verilog")
        self.geometry("900x600")
        self.carpeta = os.getcwd()
        self.vcd = None

        top = tk.Frame(self); top.pack(fill="x", padx=8, pady=6)
        tk.Button(top, text="Elegir carpeta...", command=self.elegir_carpeta).pack(side="left")
        tk.Button(top, text="Elegir archivo...", command=self.elegir_archivo).pack(side="left", padx=4)
        self.lbl = tk.Label(top, text="", anchor="w"); self.lbl.pack(side="left", padx=8)

        mid = tk.Frame(self); mid.pack(fill="x", padx=8)
        self.lista = tk.Listbox(mid, height=6, exportselection=False)
        self.lista.pack(side="left", fill="x", expand=True)
        self.lista.bind("<Double-Button-1>", lambda e: self.correr())
        bt = tk.Frame(mid); bt.pack(side="left", padx=8)
        self.btn_run = tk.Button(bt, text="Correr", width=14, command=self.correr); self.btn_run.pack(pady=2)
        self.btn_gtk = tk.Button(bt, text="Abrir GTKWave", width=14, command=self.gtkwave, state="disabled"); self.btn_gtk.pack(pady=2)

        self.out = scrolledtext.ScrolledText(self, font=("Consolas", 10), state="disabled")
        self.out.pack(fill="both", expand=True, padx=8, pady=8)
        self.out.tag_config("err", foreground="red")
        self.out.tag_config("ok", foreground="green")

        self.cargar_lista()

    def log(self, txt, tag=None):
        self.out.config(state="normal"); self.out.insert("end", txt, tag); self.out.see("end"); self.out.config(state="disabled")

    def cargar_lista(self):
        self.lbl.config(text=self.carpeta)
        self.lista.delete(0, "end")
        for x in sorted(os.listdir(self.carpeta)):
            if x.endswith("_tb.v"):
                self.lista.insert("end", x)
        if self.lista.size():
            self.lista.selection_set(0)

    def elegir_carpeta(self):
        d = filedialog.askdirectory(initialdir=self.carpeta)
        if d:
            self.carpeta = d; self.cargar_lista()

    def elegir_archivo(self):
        p = filedialog.askopenfilename(initialdir=self.carpeta, filetypes=[("Verilog", "*.v")])
        if p:
            self.carpeta = os.path.dirname(p); self.cargar_lista()
            nombres = self.lista.get(0, "end")
            if os.path.basename(p) in nombres:
                self.lista.selection_clear(0, "end"); self.lista.selection_set(nombres.index(os.path.basename(p)))
            else:
                self.lista.insert("end", os.path.basename(p)); self.lista.selection_clear(0, "end"); self.lista.selection_set("end")

    def correr(self):
        sel = self.lista.curselection()
        if not sel:
            messagebox.showinfo("Falta elegir", "Elegi un testbench de la lista."); return
        tb = self.lista.get(sel[0])
        self.btn_run.config(state="disabled"); self.btn_gtk.config(state="disabled")
        self.out.config(state="normal"); self.out.delete("1.0", "end"); self.out.config(state="disabled")
        threading.Thread(target=self._correr, args=(tb,), daemon=True).start()

    def _run(self, cmd):
        p = subprocess.Popen(cmd, cwd=self.carpeta, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                             text=True, errors="replace",
                             creationflags=0x08000000 if WIN else 0)   # sin ventana de consola
        for linea in p.stdout:
            tag = "err" if re.search(r"error|ERROR|fail|FAIL", linea) else ("ok" if re.search(r"\bok\b|PASS|pasaron", linea) else None)
            self.after(0, self.log, linea, tag)
        return p.wait()

    def _correr(self, tb):
        try:
            iv, vvp = buscar("iverilog"), buscar("vvp")
            if not iv or not vvp:
                self.after(0, self.log, "No encuentro iverilog/vvp. Instala Icarus Verilog (https://bleyer.org/icarus/) "
                           "y marca 'Add to PATH' en el instalador.\n", "err"); return
            archivos, origen = archivos_de(os.path.join(self.carpeta, tb))
            faltan = [a for a in archivos if not os.path.isfile(os.path.join(self.carpeta, a))]
            if faltan:
                self.after(0, self.log, "Faltan estos archivos en la carpeta: " + ", ".join(faltan) + "\n", "err"); return
            salida = tb[:-2] + ".vvp"
            self.after(0, self.log, f"Archivos ({origen}): {' '.join(archivos)}\n\n$ iverilog -g2012 -o {salida} ...\n")
            if self._run([iv, "-g2012", "-o", salida] + archivos) != 0:
                self.after(0, self.log, "\nFallo la compilacion.\n", "err"); return
            self.after(0, self.log, f"$ vvp {salida}\n\n")
            self._run([vvp, salida])
            vcd = os.path.join(self.carpeta, tb[:-2] + ".vcd")
            if os.path.isfile(vcd):
                self.vcd = vcd; self.after(0, lambda: self.btn_gtk.config(state="normal"))
            self.after(0, self.log, "\n--- Fin de la simulacion ---\n", "ok")
        finally:
            self.after(0, lambda: self.btn_run.config(state="normal"))

    def gtkwave(self):
        g = buscar("gtkwave")
        if not g:
            messagebox.showerror("GTKWave", "No encuentro gtkwave (viene con el instalador de Icarus Verilog)."); return
        subprocess.Popen([g, self.vcd], cwd=self.carpeta)

if __name__ == "__main__":
    App().mainloop()
