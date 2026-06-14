#!/usr/bin/env bash
# hypr-auto-float.sh
# Automatycznie ustawia okna popup/extension jako floating w Hyprlandzie
# Użycie: uruchom w tle przy starcie Hyprlanda (exec-once)

# Lista wzorców do dopasowania (class lub title okna)
# Format: "class|title" — możesz używać jednego lub obu pól
FLOAT_PATTERNS=(
    # Bitwarden
    "bitwarden"
    "Bitwarden"

    # Menedżery haseł
    "1Password"
    "keepassxc"
    "KeePassXC"
    "enpass"

    # Authenticatory / 2FA
    "authenticator"
    "Authenticator"
    "yubioath"
    "YubiKey"

    # Komunikatory — małe okna powiadomień/połączeń
    "zoom"
    "discord"
    "slack"

    # Systemowe dialogi / narzędzia
    "polkit"
    "pkexec"
    "nm-connection-editor"
    "pavucontrol"
    "PulseAudio"
    "blueman"
    "Blueman"

    # Dodaj własne wzorce poniżej
)

log() {
    echo "[$(date '+%H:%M:%S')] $*" >&2
}

make_window_float() {
    local addr="$1"
    hyprctl dispatch setfloating "address:$addr" 2>/dev/null
    hyprctl dispatch centerwindow "address:$addr" 2>/dev/null
    log "Floating: $addr"
}

matches_pattern() {
    local class="$1"
    local title="$2"
    for pattern in "${FLOAT_PATTERNS[@]}"; do
        if [[ "${class,,}" == *"${pattern,,}"* ]] || \
           [[ "${title,,}" == *"${pattern,,}"* ]]; then
            return 0
        fi
    done
    return 1
}

log "Uruchamianie monitora auto-float..."

# Nasłuchuj zdarzeń otwarcia okien przez IPC
socat - "UNIX-CONNECT:/tmp/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock" \
| while IFS= read -r event; do

    # Zdarzenie: openwindow>>address,workspace,class,title
    if [[ "$event" == openwindow* ]]; then
        IFS=',' read -r addr_raw workspace class title <<< "${event#openwindow>>}"
        addr="${addr_raw#0x}"  # usuń "0x" jeśli obecne

        if matches_pattern "$class" "$title"; then
            log "Dopasowano: class='$class' title='$title'"
            # Krótkie opóźnienie żeby okno zdążyło się zainicjować
            sleep 0.05
            make_window_float "0x${addr_raw#*>>}"
        fi
    fi

done
