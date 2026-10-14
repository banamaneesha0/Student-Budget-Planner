# SpendWise Launcher Script
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "Starting SpendWise - Personal Expense Tracker & Insights" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan

$env:JAVA_HOME = "$env:USERPROFILE\.tools\jdk-21.0.12.1+1"
$env:PATH = "$env:JAVA_HOME\bin;$env:USERPROFILE\.tools\apache-maven-3.9.6\bin;$env:PATH"

if (!(Test-Path "target\spendwise-1.0.0.jar")) {
    Write-Host "Building project artifact..." -ForegroundColor Yellow
    mvn clean package -DskipTests
}

Write-Host "Launching SpendWise at http://localhost:8080 ..." -ForegroundColor Green
& "$env:JAVA_HOME\bin\java.exe" -jar target\spendwise-1.0.0.jar
