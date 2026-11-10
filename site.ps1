<#
.SYNOPSIS
  Liga, desliga ou consulta o site (GitHub Pages) deste repositório.

.EXAMPLE
  .\site.ps1 status          # mostra se está no ar
  .\site.ps1 on              # publica o site
  .\site.ps1 on -Horas 2     # publica e agenda o desligamento automático em 2 horas
  .\site.ps1 off             # tira do ar (404) e cancela o agendamento

Requer o GitHub CLI (gh) autenticado na conta dona do repositório.
Obs.: depois de "off", o cache do GitHub pode manter a página visível por alguns minutos.
#>
param(
    [Parameter(Mandatory, Position = 0)][ValidateSet('on', 'off', 'status')][string]$Acao,
    [double]$Horas = 0
)

$ErrorActionPreference = 'Stop'
$Repo = 'jef-loppes-reis/url_redirect'
$Tarefa = 'url_redirect_desligar_site'

function Get-Pages {
    $json = gh api "repos/$Repo/pages" 2>$null
    if ($LASTEXITCODE -eq 0 -and $json) { return $json | ConvertFrom-Json }
    return $null  # 404 = Pages desativado
}

function Remove-Agendamento {
    if (Get-ScheduledTask -TaskName $Tarefa -ErrorAction SilentlyContinue) {
        Unregister-ScheduledTask -TaskName $Tarefa -Confirm:$false
    }
}

switch ($Acao) {
    'status' {
        $p = Get-Pages
        if ($p) { "NO AR: $($p.html_url)  (status: $($p.status))" } else { 'FORA DO AR (Pages desativado)' }
        $t = Get-ScheduledTask -TaskName $Tarefa -ErrorAction SilentlyContinue
        if ($t) { "Desligamento agendado para: $($t.Triggers[0].StartBoundary)" }
    }
    'on' {
        if (-not (Get-Pages)) {
            gh api -X POST "repos/$Repo/pages" -f 'source[branch]=main' -f 'source[path]=/' | Out-Null
        }
        Remove-Agendamento
        if ($Horas -gt 0) {
            $quando = (Get-Date).AddHours($Horas)
            $exe = if (Get-Command pwsh.exe -ErrorAction SilentlyContinue) { 'pwsh.exe' } else { 'powershell.exe' }
            # Atenção: variáveis do PowerShell não diferenciam maiúsculas; nunca reutilize o nome
            # do parâmetro $Acao (um "$acao" aqui sobrescreveria o parâmetro validado).
            $tarefaAcao = New-ScheduledTaskAction -Execute $exe -Argument "-NoProfile -File `"$PSCommandPath`" off"
            $tarefaGatilho = New-ScheduledTaskTrigger -Once -At $quando
            # StartWhenAvailable: se o PC estiver desligado/dormindo na hora, desliga ao voltar.
            $tarefaConfig = New-ScheduledTaskSettingsSet -StartWhenAvailable
            Register-ScheduledTask -TaskName $Tarefa -Action $tarefaAcao -Trigger $tarefaGatilho -Settings $tarefaConfig -Force | Out-Null
            "Site publicado. Desliga automaticamente em $($quando.ToString('dd/MM HH:mm'))."
        } else {
            'Site publicado. Lembre-se de rodar: .\site.ps1 off'
        }
        'Pode levar 1 a 2 minutos para aparecer: https://jef-loppes-reis.github.io/url_redirect/'
    }
    'off' {
        if (Get-Pages) { gh api -X DELETE "repos/$Repo/pages" | Out-Null }
        Remove-Agendamento
        'Site fora do ar. (O cache do GitHub pode mostrar a página por alguns minutos.)'
    }
}
