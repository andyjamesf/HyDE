# Shell Quickshell para o HyDE

Nesta edição do HyDE substitui a Waybar, o dunst, o wlogout, o hyprlock (que fica como alternativa)
e os menus de apps/clipboard/calculadora do rofi,
mantendo a integração com os temas e o wallbash. Arranca com `qs` (config por omissão em
`~/.config/quickshell`); o HyDE arranca-a no login (`hyde.config.start.bar`).

O instalador do HyDE mantém o código atualizado (é sobrescrito a cada atualização) e copia a pasta
`config/` só quando não existe: as tuas definições nunca são tocadas.

## Estrutura

| Pasta | Conteúdo |
|---|---|
| `shell.qml` | ponto de entrada: janelas por ecrã e alvos IPC |
| `services/` | singletons com a lógica (cores, áudio, rede, Bluetooth, notificações, launcher, bloqueio…) |
| `components/` | peças visuais reutilizáveis (botões, sliders, cartões, popouts…) |
| `modules/` | barra, centro de controlo, notificações, OSD, launcher, power menu, lockscreen |
| `config/config.json` | as tuas definições (só o que mudares; os valores por omissão estão em `services/Config.qml`) |
| `config/layouts.json` | presets de layout da barra (podes acrescentar os teus) |
| `scripts/ical_events.py` | leitor de calendários iCal (Google Calendar) |

## Cores e temas

As cores seguem o HyDE e mudam sozinhas, com transição, ao trocar de tema ou de wallpaper. No menu
do HyDE (ícone de paleta na barra) → **Cores da shell**:

- **Tema do HyDE** (por omissão): as cores que cada tema desenhou para a barra (`waybar.theme`).
- **Paleta do tema (wallbash)**: a paleta completa gerada por `~/.config/hyde/wallbash/always/quickshell.dcol`.
- **Cores do wallpaper**: as cores extraídas do wallpaper atual.

Todo o texto e ícones passam por uma verificação de contraste (WCAG), por isso lêem-se em temas
claros e escuros.

## config.json

```json
{
  "bar": {
    "layout": "ilhas",            // layout por omissão (ver layouts.json)
    "position": "top",            // "top" | "bottom"
    "opacity": 0.92,
    "pillStyle": "tint",          // surface | tint | container | accent | glass | outline | "#rrggbb"
    "themeLayouts": { "Catppuccin-Latte": "minimal" }   // layout automático por tema
  },
  "appearance": { "locale": "pt_PT", "font": "Inter", "fontSize": 12, "animationScale": 1 },
  "widgets": {
    "workspaces": { "shown": 5, "appIcons": true },
    "clock": { "format": "HH:mm", "showDate": false },
    "notifications": { "timeout": 6000, "maxPopups": 4, "historySize": 100 },
    "osd": { "enabled": true, "timeout": 1500 },
    "lock": { "enabled": true }  // false: usa o hyprlock do HyDE
  }
}
```

(O JSON real não aceita comentários; estão aqui só para explicar.) As alterações aplicam-se a quente.
O layout, o estilo das ilhas, as cores e o "Não incomodar" escolhidos nos menus ficam guardados em
`~/.local/state/quickshell/` e têm prioridade sobre o `config.json`.

## Atalhos

| Atalho | Ação |
|---|---|
| `Super+A` | launcher de apps (escreve uma conta para calcular) |
| `Super+Shift+V` | histórico do clipboard |
| `Super+Shift+K` | calculadora |
| `Super+Alt+C` | centro de controlo |
| `Super+Alt+↑/↓` | layout seguinte/anterior da barra |
| `Super+Ctrl+B` | esconder/mostrar a barra |
| `Super+L` | bloquear |
| `Ctrl+Alt+Delete` | power menu |

## IPC (`qs ipc show` lista tudo)

```
qs ipc call bar toggle | layout <nome> | next | prev | pill <estilo> | opacity <0..1> | popout <nome>
qs ipc call controlcenter toggle | page wifi|bluetooth|audio|notifications
qs ipc call launcher toggle | clipboard | calc | openOn <ecrã>
qs ipc call notifications toggleDnd | clear | open
qs ipc call colors source hyde|wallbash|wallpaper | toggle
qs ipc call lock lock | unlock | isLocked
qs ipc call powermenu toggle
qs ipc call shell reload
```

## Google Calendar

Cria `~/.local/share/quickshell/calendars.json` (fica fora do repositório: o endereço dá acesso de
leitura ao calendário) com o "endereço secreto no formato iCal" de cada calendário:

```json
{ "calendars": [ { "name": "Pessoal", "url": "https://calendar.google.com/calendar/ical/…/basic.ics", "color": "#8ab4f8" } ] }
```

## Voltar às peças originais do HyDE

No teu `~/.config/hypr/hyprland.lua` (a camada de overrides do HyDE):

- Waybar: `hyde.config.start.bar = "hyde-shell app -u hyde-" .. os.getenv("XDG_SESSION_DESKTOP") .. "-bar.scope -t scope -- waybar.py --watch"` (e instalar `waybar`).
- dunst: `hyde.config.start.notifications = "hyde-shell app -u hyde-" .. os.getenv("XDG_SESSION_DESKTOP") .. "-notifications.service -t service -- dunst"` (e instalar `dunst`).
- hyprlock: `"lock": { "enabled": false }` no `config.json` (o hypridle também usa o hyprlock se a shell não estiver a correr).

Se o ecrã ficar bloqueado sem conseguires entrar: num TTY (`Ctrl+Alt+F3`) corre `qs ipc call lock unlock`.
