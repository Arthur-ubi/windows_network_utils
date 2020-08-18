@echo off
rem アダプタの操作には管理者権限が必要です. コマンドプロンプトを管理者権限で実行した上で本batchを実行してください

rem チェック間隔(sec)
set interval=120

rem 文字コードをUTF-8に設定
chcp 65001 > nul

rem NIC名を設定(netsh interface show interface)
set "NIC_name=Wi-Fi_3"

rem このbatchの場所をカレントディレクトリにする
cd /d "%~dp0"

rem 現在の状態を表示 
netsh interface show interface "%NIC_name%"

:check
echo [%date% %time%] Checking adopter %NIC_name%...
netsh interface show interface %NIC_name% | find "Connect state:        Connected" > nul
if ERRORLEVEL 1 goto adapter_failure

rem 制限付きアクセス｜インターネットなし(APに接続されているが、インターネットに不通)の場合
echo [%date% %time%] Checking ping...
ping -n 1 www.google.com > nul
if ERRORLEVEL 1 goto internet_failure

rem 時間をおいてループ
timeout /t %interval% > nul
goto check


:adapter_failure
echo [%date% %time%] %NIC_name%は無効化されているようです。復旧処理を開始します。
echo %date% %time% disconnect! %NIC_name% (ERROR:adopter)>> log-wifi_auto_restart.txt
goto disable_enable

:internet_failure
echo [%date% %time%] %NIC_name%はインターネット接続を確立できません。復旧処理を開始します。
echo %date% %time% disconnect! %NIC_name% (ERROR:Internet)>> log-wifi_auto_restart.txt

:disable_enable
echo [%date% %time%] %NIC_name% を無効化して待機します。
netsh interface set interface "%NIC_name%" disable > nul
timeout /t 10
echo [%date% %time%] %NIC_name% を再起動します。
netsh interface set interface "%NIC_name%" enable > nul
timeout /t 30

rem アクセスポイント機能(SoftAP)も再開
call SoftAP_start.bat
goto check

pause