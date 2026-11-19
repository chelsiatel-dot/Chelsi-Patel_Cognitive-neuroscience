#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
DOT-NUMBER COMPARISON + CONFIDENCE  (Pilot, Version 1)   -  PsychoPy Coder script

Trial sequence
    fixation cross -> two dot clouds (brief) -> "which side had MORE dots?"
    -> confidence rating (1-6 = 50%...100%) -> short gap

Design
    * Reference cloud = 50 dots; the other cloud has 50 + delta dots.
    * Difficulty = delta: easy / medium / hard, randomly interleaved.
    * Dot size is randomised per cloud so total area is not a cue to number.
    * No feedback at any point (practice or main trials).
    * Decision and confidence are both untimed.

Keys:   LEFT / RIGHT arrow = decision     1-6 = confidence     SPACE = continue
        ESC = quit at any time (trials already completed stay in the CSV)
Output: data/<participant>_dots_<date>.csv   (one row per trial)
"""

# =====================================================================
# 1. IMPORTS
# =====================================================================
import os
import csv
import random
import numpy as np
from psychopy import visual, core, event, data, gui, monitors

# =====================================================================
# 2. PARAMETERS  (all design choices live here)
# =====================================================================
# --- stimulus / design ---
N_REF = 50                                        # dots in the reference cloud
LEVELS = {'easy': 20, 'medium': 10, 'hard': 4}    # extra dots on the "more" side
REPS_PER_CELL = 10        # 3 levels x 2 sides x 10 = 60 main trials
N_PRACTICE = 8            # easy trials, no feedback
BLOCK_SIZE = 30           # short break after every 30 main trials

# --- timing (seconds; converted to whole frames below) ---
FIX_DUR = 0.500
STIM_DUR = 0.600          # dots on screen (seconds); calibrate in the pilot
ITI = 0.400

# --- geometry (degrees of visual angle) ---
CLOUD_RADIUS = 4.0
CLOUD_OFFSET = 6.0        # centre of each cloud from fixation
DOT_SIZE_RANGE = (0.20, 0.35)   # dot size randomised between these values
MIN_DOT_DIST = 0.55       # minimum distance between dot centres (no overlap)

# --- confidence scale: keys 1-6 -> 50%...100% ---
CONF_VALUES = [0.5, 0.6, 0.7, 0.8, 0.9, 1.0]

# --- display ---
FULLSCR = True            # False only for testing
SCREEN_WIDTH_CM = 31.0    # ASUS ExpertBook B1402CVA, 14" 16:9 (approx.; verify with a ruler)
VIEW_DIST_CM = 57         # real viewing distance of the participant
SCREEN_PIX = (1920, 1080) # screen resolution in pixels

# =====================================================================
# 3. SETUP: monitor, participant dialog, data file, window
# =====================================================================
mon = monitors.Monitor('myScreen')
mon.setWidth(SCREEN_WIDTH_CM)
mon.setDistance(VIEW_DIST_CM)
mon.setSizePix(SCREEN_PIX)
mon.saveMon()

info = {'participant': '', 'session': '001'}
dlg = gui.DlgFromDict(info, title='Dot comparison confidence pilot')
if not dlg.OK:
    core.quit()
info['date'] = data.getDateStr()
info['screen_width_cm'] = SCREEN_WIDTH_CM
info['view_dist_cm'] = VIEW_DIST_CM

# data folder is always created NEXT TO THIS SCRIPT (not wherever PsychoPy was started)
try:
    base_dir = os.path.dirname(os.path.abspath(__file__))
except NameError:
    base_dir = os.getcwd()
data_dir = os.path.join(base_dir, 'data')
os.makedirs(data_dir, exist_ok=True)
fname = os.path.join(data_dir, f"{info['participant']}_dots_{info['date']}")
trial_csv_path = fname + '_trials.csv'       # one row written after EVERY trial
print('DATA FOLDER:', data_dir)
print('TRIAL FILE :', trial_csv_path)
exp = data.ExperimentHandler(name='dots_confidence', extraInfo=info,
                             dataFileName=fname, savePickle=False,
                             saveWideText=True)

win = visual.Window(size=(1600, 900), fullscr=FULLSCR, color='black',
                    units='deg', allowGUI=False, monitor='myScreen')
win.mouseVisible = False

# measure the refresh rate so durations can be counted in frames
fps = win.getActualFrameRate() or 60.0


def frames(sec):
    return max(1, int(round(sec * fps)))


N_FIX = frames(FIX_DUR)
N_STIM = frames(STIM_DUR)
N_ITI = frames(ITI)
exp.addData('measured_fps', round(fps, 2))

clock = core.Clock()

# =====================================================================
# 4. STIMULI
# =====================================================================
fix = visual.TextStim(win, text='+', height=1.0, color='white')
msg = visual.TextStim(win, text='', height=0.7, color='white', wrapWidth=26)
hint = visual.TextStim(win, text='', height=0.6, color='gray',
                       pos=(0, -7), wrapWidth=26)
trial_label = visual.TextStim(win, text='', height=0.7, color='gray',
                              pos=(0, 7))        # "Trial 1", "Trial 2", ... at the top


def make_cloud(n, centre_x):
    """n random dot positions inside a circle, none too close together."""
    pts = []
    tries = 0
    while len(pts) < n and tries < 50000:
        tries += 1
        r = CLOUD_RADIUS * np.sqrt(random.random())    # sqrt -> even spread
        th = random.random() * 2 * np.pi
        p = np.array([r * np.cos(th), r * np.sin(th)])
        if all(np.hypot(*(p - q)) > MIN_DOT_DIST for q in pts):
            pts.append(p)
    if len(pts) < n:
        raise RuntimeError('Could not fit the dots: increase CLOUD_RADIUS '
                           'or lower MIN_DOT_DIST')
    pts = np.array(pts)
    pts[:, 0] += centre_x
    return pts


def make_stim(pts, size):
    return visual.ElementArrayStim(win, nElements=len(pts), xys=pts,
                                   sizes=size, elementTex=None,
                                   elementMask='circle',
                                   colors='white', colorSpace='rgb')


# =====================================================================
# 5. HELPER FUNCTIONS
# =====================================================================
def save_row(row):
    """Append one trial to the CSV right away (header written on the first row)."""
    new_file = not os.path.exists(trial_csv_path)
    with open(trial_csv_path, 'a', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=list(row.keys()))
        if new_file:
            writer.writeheader()
        writer.writerow(row)
    # visible confirmation in PsychoPy's output panel after every saved trial
    print(f"SAVED {row['phase']} trial {row['trial']}: level={row['level']}, "
          f"correct={row['correct']}, confidence_rating={row['confidence_rating']}")


def quit_experiment():
    print('Data saved in:', trial_csv_path)
    win.close()
    core.quit()


def show_message(text, prompt='Press SPACE to continue'):
    """Show text and wait (no time limit) for SPACE."""
    msg.text = text
    hint.text = prompt
    msg.draw()
    hint.draw()
    win.flip()
    keys = event.waitKeys(keyList=['space', 'escape'])
    if 'escape' in keys:
        quit_experiment()


# =====================================================================
# 6. ONE TRIAL
# =====================================================================
def run_trial(level, more_side, phase, trial_num, block):
    delta = LEVELS[level]
    n_left = N_REF + (delta if more_side == 'left' else 0)
    n_right = N_REF + (delta if more_side == 'right' else 0)

    # random dot size per cloud (area control)
    size_l = random.uniform(*DOT_SIZE_RANGE)
    size_r = random.uniform(*DOT_SIZE_RANGE)

    # build stimuli BEFORE the timed part
    left = make_stim(make_cloud(n_left, -CLOUD_OFFSET), size_l)
    right = make_stim(make_cloud(n_right, CLOUD_OFFSET), size_r)

    # on-screen trial counter (shown before and after the dots, not during them)
    trial_label.text = (f'Practice {trial_num}' if phase == 'practice'
                        else f'Trial {trial_num}')

    # --- fixation (frame-counted) ---
    for _ in range(N_FIX):
        trial_label.draw()
        fix.draw()
        win.flip()

    # --- dots (frame-counted) ---
    event.clearEvents()
    for _ in range(N_STIM):
        left.draw()
        right.draw()
        win.flip()

    # --- decision (untimed; RT measured from screen onset) ---
    msg.text = 'Which side had MORE dots?\n\n<-  LEFT          RIGHT  ->'
    trial_label.draw()
    msg.draw()
    win.callOnFlip(clock.reset)
    win.flip()
    resp, rt = event.waitKeys(keyList=['left', 'right', 'escape'],
                              timeStamped=clock)[0]
    if resp == 'escape':
        quit_experiment()
    correct = int(resp == more_side)

    # --- confidence (untimed) ---
    msg.text = ('How confident are you that your decision was correct?\n\n'
                '1 = 50% (guessing)    2 = 60%    3 = 70%\n'
                '4 = 80%    5 = 90%    6 = 100% (certain)')
    trial_label.draw()
    msg.draw()
    win.callOnFlip(clock.reset)
    win.flip()
    ckey, crt = event.waitKeys(keyList=['1', '2', '3', '4', '5', '6', 'escape'],
                               timeStamped=clock)[0]
    if ckey == 'escape':
        quit_experiment()
    conf_rating = int(ckey)

    # --- inter-trial interval (frame-counted blank screen) ---
    for _ in range(N_ITI):
        win.flip()

    # --- save one row ---
    row = {
        'participant': info['participant'],
        'phase': phase,
        'block': block,
        'trial': trial_num,
        'level': level,
        'delta': delta,
        'n_left': n_left,
        'n_right': n_right,
        'dot_size_left': round(size_l, 3),
        'dot_size_right': round(size_r, 3),
        'more_side': more_side,
        'response': resp,
        'correct': correct,
        'rt': rt,
        'confidence_rating': conf_rating,
        'confidence': CONF_VALUES[conf_rating - 1],
        'conf_rt': crt,
        'stim_frames': N_STIM,
        'measured_fps': round(fps, 2),
    }
    for key, value in row.items():
        exp.addData(key, value)
    exp.nextEntry()
    save_row(row)                  # written to disk immediately, so nothing is lost
    return correct


# =====================================================================
# 7. EXPERIMENT FLOW
# =====================================================================
# --- instructions ---
N_MAIN = len(LEVELS) * 2 * REPS_PER_CELL      # total main trials (levels x 2 sides x reps)

show_message(
    'INSTRUCTIONS\n\n'
    'Thank you for participating in this experiment.\n\n'
    'On each trial, two clouds of dots will appear on the screen, '
    'one on the left and one on the right. A fixation cross will appear '
    'in the centre before the dots are shown.\n\n'
    'Your task is to decide which cloud contains more dots. '
    'Press the LEFT arrow key if you think the left cloud has more dots, '
    'or the RIGHT arrow key if you think the right cloud has more dots.\n\n'
    'Please keep your eyes on the centre of the screen while the dots are shown. '
    'Make your decision based on your overall impression; you do not need '
    'to count the individual dots.',
    prompt='Press SPACE to continue')

show_message(
    'CONFIDENCE RATING\n\n'
    'After each decision, rate how confident you are that your answer was correct.\n\n'
    '1 = 50%\n'
    '2 = 60%\n'
    '3 = 70%\n'
    '4 = 80%\n'
    '5 = 90%\n'
    '6 = 100%\n\n'
    'Press the number key that best matches your confidence. '
    'There is no time limit, so take a moment and respond naturally.',
    prompt='Press SPACE to continue')

show_message(
    'PROCEDURE\n\n'
    f'The experiment begins with {N_PRACTICE} practice trials, followed by '
    f'{N_MAIN} experimental trials. A short break will be given after every '
    f'{BLOCK_SIZE} trials. No feedback on your responses will be provided at any point.\n\n'
    'If you have any questions, please ask the experimenter now.',
    prompt='Press SPACE to start the practice trials')

# --- practice (no feedback) ---
for i in range(N_PRACTICE):
    run_trial('easy', random.choice(['left', 'right']),
              'practice', i + 1, 0)

show_message('The practice trials are now complete.\n\n'
             'The experimental trials will begin next.',
             prompt='Press SPACE to begin')

# --- main trials (levels randomly interleaved) ---
cond_list = [{'level': lv, 'more_side': s}
             for lv in LEVELS for s in ('left', 'right')]
trials = data.TrialHandler(trialList=cond_list, nReps=REPS_PER_CELL,
                           method='random')
exp.addLoop(trials)

n = 0
for t in trials:
    n += 1
    block = (n - 1) // BLOCK_SIZE + 1
    run_trial(t['level'], t['more_side'], 'main', n, block)
    if n % BLOCK_SIZE == 0 and n < trials.nTotal:
        show_message('Please take a short break.',
                     prompt='Press SPACE when you are ready to continue')

show_message('The experiment is now complete.\n\nThank you for your participation.',
             prompt='Press SPACE to exit')
quit_experiment()








