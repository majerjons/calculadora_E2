@echo off
rem Doble click: abre el corredor de testbenches (necesita Python instalado).
cd /d "%~dp0"
where pythonw >nul 2>nul && (start "" pythonw correr_tb.py & exit /b)
where python >nul 2>nul && (python correr_tb.py & exit /b)
echo No encuentro Python. Instalalo desde https://www.python.org/downloads/ (marca "Add to PATH").
pause
