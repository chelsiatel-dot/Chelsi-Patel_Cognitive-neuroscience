
#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
DOT-NUMBER COMPARISON + CONFIDENCE
VERSION 2 - FINAL

Trial sequence:
Fixation -> Dot clouds -> Decision -> Confidence -> ITI

DESIGN
- Reference cloud = 50 dots
- Easy: 70 vs 50
- Medium: 60 vs 50
- Hard: 54 vs 50
- 50 repetitions per difficulty x side
- 300 main trials total
- 8 practice trials
- No feedback
- Decision and confidence untimed

TIMING
- Fixation: 500 ms
- Stimulus: 500 ms
- ITI: 400 ms

KEYS
- LEFT / RIGHT arrow = decision
- 1-6 = confidence
- SPACE = continue
- ESC = quit

OUTPUT
data/<participant>_V2_dots_<date>_trials.csv
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
# 2. PARAMETERS
# =====================================================================

# --- Stimulus and design ---

N_REF = 50

LEVELS = {
    'easy': 20,
    'medium': 10,
    'hard': 4
}

REPS_PER_CELL = 50

# 3 difficulty levels x 2 sides x 50 repetitions = 300 trials

N_PRACTICE = 8

BLOCK_SIZE = 50


# --- Timing in seconds ---

FIX_DUR = 0.500
STIM_DUR = 0.500
ITI = 0.400


# --- Dot geometry (degrees of visual angle) ---

CLOUD_RADIUS = 4.0
CLOUD_OFFSET = 6.0

DOT_SIZE_RANGE = (0.20, 0.35)

MIN_DOT_DIST = 0.55


# --- Confidence scale ---

CONF_VALUES = [0.5, 0.6, 0.7, 0.8, 0.9, 1.0]

USE_FREQUENCY_CONFIDENCE = False


# --- Display ---

FULLSCR = True

SCREEN_WIDTH_CM = 31.0
VIEW_DIST_CM = 57

SCREEN_PIX = (1920, 1080)


# =====================================================================
# 3. SETUP
# =====================================================================

mon = monitors.Monitor('myScreen')

mon.setWidth(SCREEN_WIDTH_CM)
mon.setDistance(VIEW_DIST_CM)
mon.setSizePix(SCREEN_PIX)

mon.saveMon()


info = {
    'participant': '',
    'session': '001'
}

dlg = gui.DlgFromDict(
    info,
    title='Dot comparison confidence - Version 2'
)

if not dlg.OK:
    core.quit()

info['date'] = data.getDateStr()
info['screen_width_cm'] = SCREEN_WIDTH_CM
info['view_dist_cm'] = VIEW_DIST_CM
info['version'] = 'V2'


# Create data folder next to this script

try:
    base_dir = os.path.dirname(os.path.abspath(__file__))
except NameError:
    base_dir = os.getcwd()

data_dir = os.path.join(base_dir, 'data')

os.makedirs(data_dir, exist_ok=True)


# Create Version 2 filename

fname = os.path.join(
    data_dir,
    f"{info['participant']}_V2_dots_{info['date']}"
)

trial_csv_path = fname + '_trials.csv'


# Prevent accidental appending to an earlier run
# with the same participant and date.

if os.path.exists(trial_csv_path):

    raise FileExistsError(
        'A data file already exists for this participant and date:\n'
        + trial_csv_path
        + '\nPlease change the session or date before running again.'
    )


print('VERSION: V2')
print('DATA FOLDER:', data_dir)
print('TRIAL FILE:', trial_csv_path)


# PsychoPy experiment handler

exp = data.ExperimentHandler(
    name='dots_confidence_V2',
    extraInfo=info,
    dataFileName=fname,
    savePickle=False,
    saveWideText=True
)


# =====================================================================
# 4. WINDOW AND TIMING SETUP
# =====================================================================

win = visual.Window(
    size=(1600, 900),
    fullscr=FULLSCR,
    color='black',
    units='deg',
    allowGUI=False,
    monitor='myScreen'
)

win.mouseVisible = False


# Measure screen refresh rate

fps = win.getActualFrameRate() or 60.0


def frames(sec):
    return max(1, int(round(sec * fps)))


N_FIX = frames(FIX_DUR)
N_STIM = frames(STIM_DUR)
N_ITI = frames(ITI)


print('Measured FPS:', round(fps, 2))
print('Fixation frames:', N_FIX)
print('Stimulus frames:', N_STIM)
print('ITI frames:', N_ITI)


exp.addData('measured_fps', round(fps, 2))


clock = core.Clock()


# =====================================================================
# 5. STIMULI
# =====================================================================

fix = visual.TextStim(
    win,
    text='+',
    height=1.0,
    color='white'
)

msg = visual.TextStim(
    win,
    text='',
    height=0.7,
    color='white',
    wrapWidth=26
)

hint = visual.TextStim(
    win,
    text='',
    height=0.6,
    color='gray',
    pos=(0, -7),
    wrapWidth=26
)

trial_label = visual.TextStim(
    win,
    text='',
    height=0.7,
    color='gray',
    pos=(0, 7)
)


# =====================================================================
# 6. CREATE DOT CLOUDS
# =====================================================================

def make_cloud(n, centre_x):

    """Generate random dot positions inside a circular cloud."""

    pts = []
    tries = 0

    while len(pts) < n and tries < 50000:

        tries += 1

        r = CLOUD_RADIUS * np.sqrt(random.random())

        th = random.random() * 2 * np.pi

        p = np.array([
            r * np.cos(th),
            r * np.sin(th)
        ])

        if all(
            np.hypot(*(p - q)) > MIN_DOT_DIST
            for q in pts
        ):
            pts.append(p)

    if len(pts) < n:

        raise RuntimeError(
            'Could not fit the dots. Increase CLOUD_RADIUS '
            'or lower MIN_DOT_DIST.'
        )

    pts = np.array(pts)

    pts[:, 0] += centre_x

    return pts


def make_stim(pts, size):

    return visual.ElementArrayStim(
        win,
        nElements=len(pts),
        xys=pts,
        sizes=size,
        elementTex=None,
        elementMask='circle',
        colors='white',
        colorSpace='rgb'
    )


# =====================================================================
# 7. HELPER FUNCTIONS
# =====================================================================

def save_row(row):

    """Save each completed trial immediately to CSV."""

    new_file = not os.path.exists(trial_csv_path)

    with open(
        trial_csv_path,
        'a',
        newline='',
        encoding='utf-8'
    ) as f:

        writer = csv.DictWriter(
            f,
            fieldnames=list(row.keys())
        )

        if new_file:
            writer.writeheader()

        writer.writerow(row)

    print(
        f"SAVED {row['phase']} trial {row['trial']}: "
        f"level={row['level']}, "
        f"correct={row['correct']}, "
        f"confidence={row['confidence_rating']}"
    )


def quit_experiment():

    print('Data saved in:', trial_csv_path)

    win.close()

    core.quit()


def show_message(text, prompt='Press SPACE to continue'):

    """Display instructions and wait for SPACE."""

    msg.text = text
    hint.text = prompt

    msg.draw()
    hint.draw()

    win.flip()

    keys = event.waitKeys(
        keyList=['space', 'escape']
    )

    if 'escape' in keys:
        quit_experiment()


# =====================================================================
# 8. RUN ONE TRIAL
# =====================================================================

def run_trial(level, more_side, phase, trial_num, block):

    delta = LEVELS[level]

    n_left = N_REF + (
        delta if more_side == 'left' else 0
    )

    n_right = N_REF + (
        delta if more_side == 'right' else 0
    )


    # Randomise dot size for each cloud

    size_l = random.uniform(*DOT_SIZE_RANGE)
    size_r = random.uniform(*DOT_SIZE_RANGE)


    # Generate dot clouds before timed presentation

    left = make_stim(
        make_cloud(n_left, -CLOUD_OFFSET),
        size_l
    )

    right = make_stim(
        make_cloud(n_right, CLOUD_OFFSET),
        size_r
    )


    # Trial counter

    if phase == 'practice':
        trial_label.text = f'Practice {trial_num}'
    else:
        trial_label.text = f'Trial {trial_num}'


    # -------------------------------------------------
    # FIXATION
    # -------------------------------------------------

    for _ in range(N_FIX):

        trial_label.draw()
        fix.draw()

        win.flip()


    # -------------------------------------------------
    # DOT STIMULUS
    # -------------------------------------------------

    event.clearEvents()

    for _ in range(N_STIM):

        left.draw()
        right.draw()

        win.flip()


    # -------------------------------------------------
    # DECISION
    # -------------------------------------------------

    # Clear any key events from the preceding stimulus period.

    event.clearEvents()

    msg.text = (
        'Which side had MORE dots?\n\n'
        '<-  LEFT          RIGHT  ->'
    )

    trial_label.draw()
    msg.draw()

    # Start RT clock exactly when the decision screen appears.

    win.callOnFlip(clock.reset)

    win.flip()

    resp, rt = event.waitKeys(
        keyList=['left', 'right', 'escape'],
        timeStamped=clock
    )[0]

    if resp == 'escape':
        quit_experiment()

    correct = int(resp == more_side)


    # -------------------------------------------------
    # CONFIDENCE RATING
    # -------------------------------------------------

    # Clear the previous decision key before confidence response.

    event.clearEvents()

    if USE_FREQUENCY_CONFIDENCE:

        msg.text = (
            'Imagine 10 trials in which you felt exactly as you do now.\n'
            'How many of those 10 would you get right?\n\n'
            '1 = 5 out of 10 (50%, chance)\n'
            '2 = 6 out of 10 (60%)\n'
            '3 = 7 out of 10 (70%)\n'
            '4 = 8 out of 10 (80%)\n'
            '5 = 9 out of 10 (90%)\n'
            '6 = 10 out of 10 (100%)'
        )

    else:

        msg.text = (
            'How confident are you that your decision was correct?\n\n'
            '1 = 50% (guessing)    2 = 60%    3 = 70%\n'
            '4 = 80%    5 = 90%    6 = 100% (certain)'
        )

    trial_label.draw()
    msg.draw()

    # Start confidence RT clock when confidence screen appears.

    win.callOnFlip(clock.reset)

    win.flip()

    ckey, crt = event.waitKeys(
        keyList=[
            '1', '2', '3',
            '4', '5', '6',
            'escape'
        ],
        timeStamped=clock
    )[0]

    if ckey == 'escape':
        quit_experiment()

    conf_rating = int(ckey)


    # -------------------------------------------------
    # INTER-TRIAL INTERVAL
    # -------------------------------------------------

    for _ in range(N_ITI):

        win.flip()


    # -------------------------------------------------
    # SAVE TRIAL DATA
    # -------------------------------------------------

    row = {

        'participant': info['participant'],
        'version': 'V2',
        'session': info['session'],

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
        'measured_fps': round(fps, 2)
    }


    for key, value in row.items():

        exp.addData(key, value)

    exp.nextEntry()

    save_row(row)

    return correct


# =====================================================================
# 9. EXPERIMENT FLOW
# =====================================================================

N_MAIN = (
    len(LEVELS) * 2 * REPS_PER_CELL
)

print('Total main trials:', N_MAIN)


# -------------------------------------------------
# GENERAL INSTRUCTIONS
# -------------------------------------------------

show_message(

    'INSTRUCTIONS\n\n'

    'Thank you for participating in this experiment.\n\n'

    'On each trial, two clouds of dots will appear '
    'on the screen, one on the left and one on the right. '

    'A fixation cross will appear in the centre '
    'before the dots are shown.\n\n'

    'Your task is to decide which cloud contains more dots. '

    'Press the LEFT arrow key if you think the left cloud '
    'has more dots, or the RIGHT arrow key if you think '
    'the right cloud has more dots.\n\n'

    'Please keep your eyes on the centre of the screen '
    'while the dots are shown. '

    'Make your decision based on your overall impression; '
    'you do not need to count the individual dots.',

    prompt='Press SPACE to continue'
)


# -------------------------------------------------
# CONFIDENCE INSTRUCTIONS
# -------------------------------------------------

if USE_FREQUENCY_CONFIDENCE:

    show_message(

        'CONFIDENCE RATING\n\n'

        'After each decision, imagine 10 trials in which you felt '
        'exactly as you do now. Rate how many of those 10 you '
        'would expect to get right.\n\n'

        '1 = 5 out of 10 (50%)\n'
        '2 = 6 out of 10 (60%)\n'
        '3 = 7 out of 10 (70%)\n'
        '4 = 8 out of 10 (80%)\n'
        '5 = 9 out of 10 (90%)\n'
        '6 = 10 out of 10 (100%)\n\n'

        'Try to make your rating match how often you would '
        'really be correct. There is no time limit.',

        prompt='Press SPACE to continue'
    )

else:

    show_message(

        'CONFIDENCE RATING\n\n'

        'After each decision, rate how confident you are '
        'that your answer was correct.\n\n'

        '1 = 50%\n'
        '2 = 60%\n'
        '3 = 70%\n'
        '4 = 80%\n'
        '5 = 90%\n'
        '6 = 100%\n\n'

        'Press the number key that best matches your confidence. '

        'There is no time limit, so take a moment '
        'and respond naturally.',

        prompt='Press SPACE to continue'
    )


# -------------------------------------------------
# PROCEDURE INSTRUCTIONS
# -------------------------------------------------

show_message(

    'PROCEDURE\n\n'

    f'The experiment begins with {N_PRACTICE} practice trials, '
    f'followed by {N_MAIN} experimental trials.\n\n'

    f'A short break will be given after every '
    f'{BLOCK_SIZE} experimental trials.\n\n'

    'No feedback on your responses will be provided '
    'at any point.\n\n'

    'If you have any questions, please ask the '
    'experimenter now.',

    prompt='Press SPACE to start the practice trials'
)


# =====================================================================
# 10. PRACTICE TRIALS
# =====================================================================

for i in range(N_PRACTICE):

    run_trial(
        'easy',
        random.choice(['left', 'right']),
        'practice',
        i + 1,
        0
    )


show_message(

    'The practice trials are now complete.\n\n'
    'The experimental trials will begin next.',

    prompt='Press SPACE to begin'
)


# =====================================================================
# 11. MAIN EXPERIMENTAL TRIALS
# =====================================================================

cond_list = [

    {
        'level': lv,
        'more_side': side
    }

    for lv in LEVELS
    for side in ('left', 'right')
]


trials = data.TrialHandler(

    trialList=cond_list,

    nReps=REPS_PER_CELL,

    method='random'
)


exp.addLoop(trials)


n = 0


for t in trials:

    n += 1

    block = (
        (n - 1) // BLOCK_SIZE
    ) + 1


    run_trial(

        t['level'],
        t['more_side'],

        'main',

        n,
        block
    )


    # Break after every 50 main trials.

    if n % BLOCK_SIZE == 0 and n < trials.nTotal:

        show_message(

            'Please take a short break.',

            prompt='Press SPACE when you are ready to continue'
        )


# =====================================================================
# 12. END EXPERIMENT
# =====================================================================

show_message(

    'The experiment is now complete.\n\n'
    'Thank you for your participation.',

    prompt='Press SPACE to exit'
)


quit_experiment()





