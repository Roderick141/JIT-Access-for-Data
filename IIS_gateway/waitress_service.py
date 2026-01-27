import win32serviceutil
import win32service
import win32event
import servicemanager
import subprocess
import os

class WaitressService(win32serviceutil.ServiceFramework):
    _svc_name_ = "FlaskWaitress"
    _svc_display_name_ = "Flask Waitress Service"
    _svc_description_ = "Runs Flask app via Waitress"

    def __init__(self, args):
        super().__init__(args)
        self.hWaitStop = win32event.CreateEvent(None, 0, 0, None)
        self.proc = None

    def SvcStop(self):
        self.ReportServiceStatus(win32service.SERVICE_STOP_PENDING)
        if self.proc and self.proc.poll() is None:
            self.proc.terminate()
        win32event.SetEvent(self.hWaitStop)

    def SvcDoRun(self):
        servicemanager.LogMsg(servicemanager.EVENTLOG_INFORMATION_TYPE,
                              servicemanager.PYS_SERVICE_STARTED,
                              (self._svc_name_, ""))

        app_dir = r"C:\apps\flaskapp"
        python_exe = r"C:\apps\flaskapp\.venv\Scripts\python.exe"

        # Start waitress
        self.proc = subprocess.Popen(
            [python_exe, "-m", "waitress", "--host=127.0.0.1", "--port=5001", "wsgi:app"],
            cwd=app_dir,
            stdout=open(os.path.join(app_dir, "logs", "stdout.log"), "a"),
            stderr=open(os.path.join(app_dir, "logs", "stderr.log"), "a"),
        )

        win32event.WaitForSingleObject(self.hWaitStop, win32event.INFINITE)

if __name__ == "__main__":
    win32serviceutil.HandleCommandLine(WaitressService)
