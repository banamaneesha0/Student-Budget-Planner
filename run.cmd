@echo off
setlocal
echo ========================================================
echo Starting SpendWise - Personal Expense Tracker & Insights
echo ========================================================

set "JAVA_HOME=%USERPROFILE%\.tools\jdk-21.0.12.1+1"
set "PATH=%JAVA_HOME%\bin;%USERPROFILE%\.tools\apache-maven-3.9.6\bin;%PATH%"

if not exist "%JAVA_HOME%\bin\java.exe" (
    echo Java runtime not found in %JAVA_HOME%. Using system java...
    java -jar target\spendwise-1.0.0.jar
) else (
    "%JAVA_HOME%\bin\java.exe" -jar target\spendwise-1.0.0.jar
)

pause
