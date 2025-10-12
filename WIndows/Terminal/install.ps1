Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

# Criar a janela
$form = New-Object System.Windows.Forms.Form
$form.Text = "Customization Installer"
$form.Size = New-Object System.Drawing.Size(800,600)
$form.BackColor = [System.Drawing.Color]::Black
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$form.ControlBox = $true
$form.MaximizeBox = $false
$form.MinimizeBox = $false

# Label de título
$label = New-Object System.Windows.Forms.Label
$label.Text = "Install your Customization"
$label.AutoSize = $true
$label.ForeColor = [System.Drawing.Color]::White
$label.Font = New-Object System.Drawing.Font("Arial",24,[System.Drawing.FontStyle]::Bold)
$label.Location = New-Object System.Drawing.Point(200,150)
$form.Controls.Add($label)

# Label de status
$status = New-Object System.Windows.Forms.Label
$status.Text = "Aguardando instalação..."
$status.AutoSize = $true
$status.ForeColor = [System.Drawing.Color]::LightGray
$status.Font = New-Object System.Drawing.Font("Arial",12,[System.Drawing.FontStyle]::Regular)
$status.Location = New-Object System.Drawing.Point(200,220)
$form.Controls.Add($status)

# Botão de instalação
$button = New-Object System.Windows.Forms.Button
$button.Text = "Install"
$button.Size = New-Object System.Drawing.Size(150,50)
$button.Location = New-Object System.Drawing.Point(325,300)
$button.BackColor = [System.Drawing.Color]::Gray
$button.ForeColor = [System.Drawing.Color]::White
$button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat

# Evento do botão
$button.Add_Click({
    $button.Enabled = $false
    $status.Text = "Instalando, aguarde..."

    Start-Job -ScriptBlock {
        param($SCRIPT_DIR,$USER_HOME,$LOCAL_APP_DATA)

        $ErrorActionPreference="Stop"
        Set-Location $SCRIPT_DIR

        # Instalações
        winget install --id=Microsoft.PowerShell --silent --accept-package-agreements --accept-source-agreements --force | Out-Null
        winget install --id=Fastfetch-cli.Fastfetch -e --silent --accept-package-agreements --accept-source-agreements --force | Out-Null
        winget install --id=wez.wezterm -e --silent --accept-package-agreements --accept-source-agreements --force | Out-Null

        # Copiar logo
        if (-not (Test-Path "$SCRIPT_DIR\image\logo.png")) {exit 1}
        Copy-Item "$SCRIPT_DIR\image\logo.png" "$USER_HOME\Pictures\logo.png" -Force | Out-Null

        # Config Fastfetch
        if (-not (Test-Path "$USER_HOME\.config")) {New-Item -ItemType Directory -Path "$USER_HOME\.config" | Out-Null}
        if (-not (Test-Path "$USER_HOME\.config\fastfetch")) {New-Item -ItemType Directory -Path "$USER_HOME\.config\fastfetch" | Out-Null}
        if (-not (Test-Path "$SCRIPT_DIR\.config\fastfetch\config.jsonc")) {exit 1}
        $newPath="$USER_HOME\Pictures\logo.png".Replace('\','\\')
        (Get-Content "$SCRIPT_DIR\.config\fastfetch\config.jsonc" -Raw) -replace "C:\\\\Users\\\\user\\\\Pictures\\\\logo.png",$newPath | Set-Content "$USER_HOME\.config\fastfetch\config.jsonc" -NoNewline | Out-Null

        # Config Oh My Posh
        if (Test-Path "$LOCAL_APP_DATA\Programs\oh-my-posh") {
            if (-not (Test-Path "$LOCAL_APP_DATA\Programs\oh-my-posh\themes")) {New-Item -ItemType Directory -Path "$LOCAL_APP_DATA\Programs\oh-my-posh\themes" | Out-Null}
            if (-not (Test-Path "$SCRIPT_DIR\oh-my-posh\mybar.omp.json")) {exit 1}
            Copy-Item "$SCRIPT_DIR\oh-my-posh\mybar.omp.json" "$LOCAL_APP_DATA\Programs\oh-my-posh\themes\mybar.omp.json" -Force | Out-Null

            if (-not (Test-Path $PROFILE)) {New-Item -Path $PROFILE -ItemType File -Force | Out-Null}
            Add-Content -Path $PROFILE -Value "fastfetch" | Out-Null
            Add-Content -Path $PROFILE -Value "oh-my-posh init pwsh --config `"$env:LOCALAPPDATA\Programs\oh-my-posh\themes\mybar.omp.json`" | Invoke-Expression" | Out-Null
        }

        # Config WezTerm
        if (-not (Test-Path "$SCRIPT_DIR\.wezterm.lua")) {exit 1}
        Copy-Item "$SCRIPT_DIR\.wezterm.lua" "$USER_HOME\.wezterm.lua" -Force | Out-Null

    } -ArgumentList $PSScriptRoot,$env:USERPROFILE,$env:LOCALAPPDATA | Out-Null

    Register-ObjectEvent -InputObject (Get-Job) -EventName StateChanged -Action {
        if ($EventArgs.JobStateInfo.State -eq "Completed") {
            $form.Invoke({
                $status.Text = "Instalação concluída!"
                [System.Windows.Forms.MessageBox]::Show("Installation completed!","Success",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
                $button.Enabled = $true
            })
        }
    } | Out-Null
})

$form.Controls.Add($button)

# Fade in da janela
$form.Opacity = 0
$form.Show()
for ($i = 0; $i -le 1; $i += 0.1) {
    $form.Opacity = $i
    Start-Sleep -Milliseconds 50
}
$form.Refresh()
[System.Windows.Forms.Application]::Run($form)
