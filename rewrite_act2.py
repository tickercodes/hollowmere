import json

def make_ep(ep_id, nodes, start="start", title=None):
    number = int(ep_id.replace("ep", ""))
    return {"id": ep_id, "number": number, "title": title or ep_id, "start": start, "nodes": nodes}

def save_json(path, data):
    with open(path, 'w') as f:
        json.dump(data, f, indent=2)

class Builder:
    def __init__(self):
        self.nodes = {}
    def add(self, key, val):
        self.nodes[key] = val
        return key
    def scene(self, key, lines, nxt, image=None, voice=None, title=None, effects=None):
        node = {"type": "scene", "lines": lines, "next": nxt}
        if image: node["image"] = image
        if voice: node["voice"] = voice
        if title: node["title"] = title
        if effects: node["effects"] = effects
        self.add(key, node)
    def msg(self, key, thread, text, nxt, delay=1.0, sender=None, effects=None):
        node = {"type": "message", "thread": thread, "text": text, "next": nxt, "delay": delay}
        if sender: node["from"] = sender
        if effects: node["effects"] = effects
        self.add(key, node)
    def choice(self, key, thread, options):
        self.add(key, {"type": "choice", "thread": thread, "options": options})
    def notif(self, key, app, title, body, nxt, effects=None):
        node = {"type": "notification", "app": app, "title": title, "body": body, "next": nxt}
        if effects: node["effects"] = effects
        self.add(key, node)
    def goal(self, key, text, target, nxt, effects=None):
        node = {"type": "goal", "text": text, "target": target, "next": nxt}
        if effects: node["effects"] = effects
        self.add(key, node)
    def minigame(self, key, game, title, config, hints, nxt, effects=None, evidence=None):
        node = {"type": "minigame", "game": game, "title": title, "config": config, "hints": hints, "next": nxt}
        if effects: node["effects"] = effects
        if evidence: node["evidence"] = evidence
        self.add(key, node)
    def end(self, key, teaser, next_ep=None):
        node = {"type": "end_episode"}
        if teaser: node["teaser"] = teaser
        if next_ep: node["next_episode"] = next_ep
        self.add(key, node)


# Rewrite EPISODE 19: The Core (Dense, High-Stakes)
b = Builder()
b.scene("start", ["You navigate deeper into the subterranean facility.", "The air is thick with the heat of hundreds of servers.", "A massive steel door blocks the main data hub."], "m1", image="ev_server_farm")
b.msg("m1", "unknown", "That's the Core. All of Ardis's offshore accounts, the state governor's bribes, the cartel ledgers... it's all in there.", "m2")
b.msg("m2", "unknown", "I can route you the server room's manual override, but it's heavily encrypted.", "g1")
b.goal("g1", "Hack the server node override.", {"app": "cloud"}, "mg1")
b.minigame("mg1", "wire_cut", "Core Firewall", {"wires": ["red", "purple", "black"], "correct_order": ["black", "red", "purple"], "brief": "Cut the ground wire (black), then the primary power (red), then data (purple)."}, ["Black, Red, Purple."], "s2")
b.scene("s2", ["The heavy steel door slides open.", "Inside, a single terminal blinks with a global map.", "You insert the extraction drive."], "m3")
b.msg("m3", "unknown", "Data is extracting. 50%... 70%...", "m4")
b.msg("m4", "unknown", "Wait. Someone just triggered the lockdown protocols.", "c1")
b.choice("c1", "unknown", [
    {"text": "Who is it?", "next": "m5"},
    {"text": "Can you stop it?", "next": "m5"}
])
b.msg("m5", "unknown", "It's the Governor's personal detail. They've found the facility.", "end19")
b.end("end19", "Episode 20 - The Extraction", "ep20")
save_json('assets/story/ep19.json', make_ep("ep19", b.nodes, title="The Blackout"))


# Rewrite EPISODE 20: The Extraction (Climax of Act 2)
b = Builder()
b.scene("start", ["The facility's alarms blare. Red emergency lights bathe the servers.", "Extraction complete.", "You pull the drive, but the exit is blocked by heavily armed men."], "m1")
b.msg("m1", "unknown", "You have to use the ventilation shaft above the core. I'll overload the cooling system to create a distraction.", "m2")
b.msg("m2", "unknown", "You need to manually synchronize the fan frequencies so they tear themselves apart.", "g1")
b.goal("g1", "Open the cloud to overload the cooling fans.", {"app": "cloud"}, "mg1")
b.minigame("mg1", "signal_hack", "Cooling Overload", {"target_freq": 115.0, "target_amp": 95.0, "brief": "Push the frequency and amplitude to their maximum structural limits to shatter the fan blades."}, ["Match the highest peaks."], "s2")
b.scene("s2", ["A deafening screech fills the room as the massive exhaust fans shatter.", "Thick white coolant smoke floods the room.", "You scramble up the scaffolding and into the vents, completely unseen."], "m3")
b.msg("m3", "unknown", "You made it out.", "m4")
b.msg("m4", "unknown", "We have the data. The governor, the cartel, Ardis... they are finished.", "s3")
b.scene("s3", ["You emerge into the freezing night air, miles from Hollowmere.", "You look at the drive in your hand. The truth.", "The game is finally over."], "end20")
b.end("end20", None, None)
save_json('assets/story/ep20.json', make_ep("ep20", b.nodes, title="The Extraction"))

print("Act 2 rewritten to eliminate filler.")
