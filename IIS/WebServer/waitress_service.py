import win32serviceutil
import win32service
import win32event
import servicemanager
import subprocess
import os
import sys
import time

class WaitressService(win32serviceutil.ServiceFramework):
    _svc_name_ = "FlaskWaitress"
    _svc_display_name_ = "Flask Waitress Service"
    _svc_description_ = "Runs Flask app via Waitress"

    def __init__(self, args):
        super().__init__(args)
        self.hWaitStop = win32event.CreateEvent(None, 0, 0, None)
        self.proc = None
        self.stdout_file = None
        self.stderr_file = None

    def SvcStop(self):
        self.ReportServiceStatus(win32service.SERVICE_STOP_PENDING)
        servicemanager.LogMsg(servicemanager.EVENTLOG_INFORMATION_TYPE,
                              servicemanager.PYS_SERVICE_STOPPED,
                              (self._svc_name_, ""))
        
        if self.proc:
            try:
                if self.proc.poll() is None:
                    self.proc.terminate()
                    # Wait up to 10 seconds for graceful shutdown
                    try:
                        self.proc.wait(timeout=10)
                    except subprocess.TimeoutExpired:
                        self.proc.kill()
                        self.proc.wait()
            except Exception as e:
                servicemanager.LogErrorMsg(f"Error stopping process: {e}")
        
        # Close log files
        if self.stdout_file:
            try:
                self.stdout_file.close()
            except:
                pass
        if self.stderr_file:
            try:
                self.stderr_file.close()
            except:
                pass
        
        win32event.SetEvent(self.hWaitStop)

    def SvcDoRun(self):
        servicemanager.LogMsg(servicemanager.EVENTLOG_INFORMATION_TYPE,
                              servicemanager.PYS_SERVICE_STARTED,
                              (self._svc_name_, ""))

        # Get the directory where this script is located
        script_dir = os.path.dirname(os.path.abspath(__file__))
        # Flask app is in flask_app directory (parent of IIS/WebServer)
        project_root = os.path.dirname(os.path.dirname(script_dir))
        flask_app_dir = os.path.join(project_root, "flask_app")
        
        # Determine Python executable
        # Try to use the Python that's running this script
        python_exe = sys.executable
        
        # Alternative: Use virtual environment if it exists
        venv_python = os.path.join(project_root, ".venv", "Scripts", "python.exe")
        if os.path.exists(venv_python):
            python_exe = venv_python
        
        # Create logs directory if it doesn't exist
        logs_dir = os.path.join(project_root, "logs")
        os.makedirs(logs_dir, exist_ok=True)
        
        stdout_path = os.path.join(logs_dir, "stdout.log")
        stderr_path = os.path.join(logs_dir, "stderr.log")
        
        try:
            # Open log files
            self.stdout_file = open(stdout_path, "a", encoding="utf-8")
            self.stderr_file = open(stderr_path, "a", encoding="utf-8")
            
            servicemanager.LogMsg(servicemanager.EVENTLOG_INFORMATION_TYPE,
                                  servicemanager.PYS_SERVICE_STARTED,
                                  (f"Starting Waitress in {flask_app_dir}", f"Python: {python_exe}"))
            
            # Start waitress
            # Change to flask_app directory so wsgi:app can be found
            self.proc = subprocess.Popen(
                [python_exe, "-m", "waitress", "--host=127.0.0.1", "--port=5001", "wsgi:app"],
                cwd=flask_app_dir,
                stdout=self.stdout_file,
                stderr=self.stderr_file,
                env=os.environ.copy()  # Preserve environment variables
            )
            
            # Wait a moment to see if process starts successfully
            time.sleep(2)
            
            if self.proc.poll() is not None:
                # Process exited immediately - something went wrong
                error_msg = f"Waitress process exited immediately with code {self.proc.returncode}"
                servicemanager.LogErrorMsg(error_msg)
                self.stdout_file.write(f"\n{error_msg}\n")
                self.stdout_file.flush()
                return
            
            servicemanager.LogMsg(servicemanager.EVENTLOG_INFORMATION_TYPE,
                                  servicemanager.PYS_SERVICE_STARTED,
                                  (f"Waitress started successfully (PID: {self.proc.pid})", ""))
            
            # Wait for stop signal
            win32event.WaitForSingleObject(self.hWaitStop, win32event.INFINITE)
            
        except Exception as e:
            error_msg = f"Failed to start Waitress: {e}"
            servicemanager.LogErrorMsg(error_msg)
            if self.stderr_file:
                self.stderr_file.write(f"\n{error_msg}\n")
                import traceback
                self.stderr_file.write(traceback.format_exc())
                self.stderr_file.flush()

if __name__ == "__main__":
    win32serviceutil.HandleCommandLine(WaitressService)
