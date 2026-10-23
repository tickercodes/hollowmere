import json

def load(path):
    with open(path, 'r') as f:
        return json.load(f)

def save(path, data):
    with open(path, 'w') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

es = load('assets/l10n/es.json')
pt = load('assets/l10n/pt_BR.json')

fixes = {
  "Town Hall? Are you crazy? Ardis is headed there now!": {
    "es": "¿Al Ayuntamiento? ¿Perdiste la cabeza? ¡Ardis va para allá ahora mismo!",
    "pt": "Prefeitura? Você perdeu o juízo? A Ardis está indo para lá agora!"
  }
}

for eng, trans in fixes.items():
    if eng in es:
        es[eng] = trans["es"]
    if eng in pt:
        pt[eng] = trans["pt"]

save('assets/l10n/es.json', es)
save('assets/l10n/pt_BR.json', pt)
print("Fixed 'crazy' to be gender neutral.")
