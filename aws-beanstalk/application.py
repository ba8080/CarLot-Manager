import subprocess
import sys
import os

def main():
    """
    Beanstalk application wrapper that starts the Streamlit application
    """
    # Change to the correct directory
    os.chdir('/var/app/current')
    
    # Start Streamlit application
    subprocess.run([
        sys.executable, '-m', 'streamlit', 'run', 
        'website/app.py', 
        '--server.port=8501', 
        '--server.address=0.0.0.0'
    ])

if __name__ == '__main__':
    main()