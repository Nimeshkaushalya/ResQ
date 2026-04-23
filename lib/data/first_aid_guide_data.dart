import 'package:flutter/material.dart';

class FirstAidStep {
  final String instruction;
  final String? imagePath;

  const FirstAidStep({
    required this.instruction,
    this.imagePath,
  });
}

class FirstAidCategory {
  final String id;
  final String title;
  final IconData icon;
  final String description;
  final List<FirstAidStep> steps;
  final List<String> warnings;
  final List<String> dos;
  final List<String> donts;
  final bool requiresEmergency;
  final bool usesRecoveryPosition;

  const FirstAidCategory({
    required this.id,
    required this.title,
    required this.icon,
    required this.description,
    required this.steps,
    this.warnings = const [],
    this.dos = const [],
    this.donts = const [],
    this.requiresEmergency = false,
    this.usesRecoveryPosition = false,
  });
}

// ---------------------------------------------------------
// STATIC DATABASE: St. John Ambulance Style
// ---------------------------------------------------------
final List<FirstAidCategory> firstAidDatabase = [
  const FirstAidCategory(
    id: 'burns',
    title: 'Burns & Scalds',
    icon: Icons.local_fire_department,
    description:
        'Immediate cooling is critical to prevent further skin damage. Act quickly to remove heat from the wound.',
    requiresEmergency: true,
    steps: [
      FirstAidStep(
        instruction:
            'Move the person away from the heat source immediately to stop the burning.',
        imagePath: 'assets/images/first_aid/burn_step1.png',
      ),
      FirstAidStep(
        instruction:
            'Cool the burn with cool or lukewarm running water for at least 20 minutes. DO NOT use ice, iced water, or any creams or greasy substances.',
        imagePath: 'assets/images/first_aid/burn_step2.png',
      ),
      FirstAidStep(
        instruction:
            'Remove any clothing or jewelry that is near the burnt area of skin, including babies\' nappies, but DO NOT move anything that is stuck to the skin.',
        imagePath: 'assets/images/first_aid/FirstAid-Burns-infographic.png',
      ),
      FirstAidStep(
        instruction:
            'Cover the burn with a layer of cling film. Put the cling film over the burn, rather than wrapping it around a limb. A clean clear plastic bag can be used for burns on your hand.',
      ),
    ],
    warnings: [
      'Call Emergency Services if the burn is deep, larger than the person\'s hand, or on the face, hands, feet, or genitals.',
    ],
    dos: [
      'Cool the burn immediately.',
      'Remove constricting items (watches, rings) before swelling starts.',
      'Keep the person warm with a blanket avoiding the burnt area.',
    ],
    donts: [
      'Do NOT pop blisters.',
      'Do NOT apply ointments, butter, or toothpaste.',
      'Do NOT place ice directly on the burn.',
    ],
  ),
  const FirstAidCategory(
    id: 'bleeding',
    title: 'Severe Bleeding',
    icon: Icons.bloodtype,
    description:
        'When bleeding is severe, it can be life-threatening. The main aim is to prevent further blood loss and minimize the effects of shock.',
    requiresEmergency: true,
    steps: [
      FirstAidStep(
        instruction:
            'Press it: Apply direct pressure to the wound with your hands ideally over a clean dressing or cloth.',
        imagePath: 'assets/images/first_aid/w1.png',
      ),
      FirstAidStep(
        instruction:
            'Call EMS: Call emergency services or get a helper to do it. Continue applying pressure.',
        imagePath: 'assets/images/first_aid/w2.png',
      ),
      FirstAidStep(
        instruction:
            'Firmly secure a dressing with a bandage to maintain pressure, but make sure it isn\'t so tight it cuts off circulation.',
      ),
      FirstAidStep(
        instruction:
            'If bleeding shows through the dressing, do not remove it, but add a second dressing on top.',
      ),
    ],
    dos: [
      'Apply continuous, firm pressure.',
      'Keep the injured person lying down if they feel lightheaded.',
      'Treat for shock (keep them warm and calm).',
    ],
    donts: [
      'Do NOT remove an embedded object (apply pressure around it instead).',
      'Do NOT wash a major wound.',
    ],
  ),
  const FirstAidCategory(
    id: 'choking',
    title: 'Choking (Adult/Child)',
    icon: Icons.no_food,
    description:
        'Choking occurs when an object blocks the airway. You need to clear the blockage quickly so they can breathe.',
    requiresEmergency: true,
    steps: [
      FirstAidStep(
        instruction:
            'Encourage them to cough. If the blockage is partial, coughing is the most effective way to clear it.',
        imagePath: 'assets/images/first_aid/3.png',
      ),
      FirstAidStep(
        instruction:
            'If coughing doesn\'t work, give up to 5 back blows. Lean them forward and firmly strike them between the shoulder blades with the heel of your hand.',
        imagePath: 'assets/images/first_aid/1.png',
      ),
      FirstAidStep(
        instruction:
            'If back blows fail, give up to 5 abdominal thrusts (Heimlich maneuver). Stand behind them, link your hands between their belly button and bottom of chest, and pull sharply inwards and upwards.',
        imagePath: 'assets/images/first_aid/2.png',
      ),
      FirstAidStep(
        instruction:
            'Alternate between 5 back blows and 5 abdominal thrusts until the object dislodges. Call EMS if it does not clear.',
      ),
    ],
    dos: [
      'Act quickly.',
      'Support the person’s chest when giving back blows.',
    ],
    donts: [
      'Do NOT perform abdominal thrusts on infants (under 1 year) or pregnant women.',
      'Do NOT blindly sweep the mouth with your fingers.',
    ],
  ),
  const FirstAidCategory(
    id: 'cpr',
    title: 'CPR (Adult)',
    icon: Icons.monitor_heart,
    description:
        'Cardiopulmonary Resuscitation (CPR) is an emergency procedure used when a person’s heart has stopped beating or they are not breathing normally.',
    requiresEmergency: true,
    steps: [
      FirstAidStep(
        instruction:
            'Check for danger, then check for a response. Gently shake their shoulders and ask loudly, "Are you alright?"',
        imagePath: 'assets/images/first_aid/cr1.png',
      ),
      FirstAidStep(
        instruction:
            'If there is no response, open the airway. Tilt their head back and lift their chin.',
        imagePath: 'assets/images/first_aid/cr2.png',
      ),
      FirstAidStep(
        instruction:
            'Check breathing. Look, listen, and feel for normal breathing for no more than 10 seconds. If not breathing normally, call EMS immediately.',
      ),
      FirstAidStep(
        instruction:
            'Start CPR. Place the heel of one hand in the centre of their chest, interlock the other, and give 30 chest compressions at a rate of 100-120 per minute.',
        imagePath: 'assets/images/first_aid/cr3.png',
      ),
      FirstAidStep(
        instruction:
            'Give 2 rescue breaths (optional if untrained/uncomfortable). Pinch their nose, seal your mouth over theirs, and blow steadily for 1 second until the chest rises.',
        imagePath: 'assets/images/first_aid/cr4.png',
      ),
      FirstAidStep(
        instruction:
            'Continue the cycle of 30 compressions and 2 breaths until help arrives or they start breathing normally.',
      ),
    ],
    dos: [
      'Push hard and fast in the center of the chest.',
      'Allow the chest to fully recoil between compressions.',
      'Use an AED (Automated External Defibrillator) as soon as one is available.',
    ],
    donts: [
      'Do NOT stop compressions unless necessary.',
      'Do NOT be afraid to perform CPR—doing something is better than doing nothing.',
    ],
  ),
  const FirstAidCategory(
    id: 'fractures',
    title: 'Fractures & Sprains',
    icon: Icons.personal_injury,
    description:
        'A fracture is a break or crack in a bone. The main aim is to keep the injured area still to prevent further damage.',
    requiresEmergency: true,
    steps: [
      FirstAidStep(
        instruction:
            'Advise the person to keep the injured limb still. Support the joints above and below the injury with your hands or padding.',
        imagePath: 'assets/images/first_aid/fracture_step1.png',
      ),
      FirstAidStep(
        instruction:
            'If it is a suspected sprain, apply the RICE method: Rest, Ice (wrapped in cloth), Comfortable support (bandage), Elevation.',
      ),
      FirstAidStep(
        instruction:
            'If it is a severe fracture (bone exposed or deformed), call EMS immediately. DO NOT move the limb.',
      ),
      FirstAidStep(
        instruction:
            'If there is an open wound, cover it with a sterile dressing or clean cloth to stop bleeding and prevent infection.',
      ),
    ],
    dos: [
      'Keep the injured part supported and still.',
      'Use padding (clothing/blankets) to support the break.',
    ],
    donts: [
      'Do NOT try to push a protruding bone back into place.',
      'Do NOT give them anything to eat or drink in case they need surgery.',
    ],
  ),
  const FirstAidCategory(
    id: 'snakebite',
    title: 'Snake Bite',
    icon: Icons.pest_control,
    description:
        'Snake bites can be deadly. The most important initial step is to keep the patient calm and completely still to slow the spread of venom.',
    requiresEmergency: true,
    steps: [
      FirstAidStep(
        instruction:
            'Ensure the scene is safe. Move away from the snake but DO NOT try to catch or kill it.',
        imagePath: 'assets/images/first_aid/snake_step1.png',
      ),
      FirstAidStep(
        instruction:
            'Call EMS immediately. Note the time of the bite and remember the snake’s appearance if possible.',
      ),
      FirstAidStep(
        instruction:
            'Keep the person completely still and calm. Movement pushes venom through the lymphatic system faster.',
      ),
      FirstAidStep(
        instruction:
            'Apply a pressure immobilization bandage (if trained and appropriate for the region/snake type). Wrap firmly around the entire bitten limb, starting from the extremities towards the body. Add a splint to restrict movement entirely.',
      ),
    ],
    dos: [
      'Keep the bitten limb below heart level if possible.',
      'Remove tight clothing and jewelry before swelling occurs.',
    ],
    donts: [
      'Do NOT cut the wound.',
      'Do NOT attempt to suck out the venom.',
      'Do NOT apply a tourniquet (unless specifically trained for immediate life threat).',
      'Do NOT apply ice or wash the bite (medical staff may need the venom for identification).',
    ],
  ),
  const FirstAidCategory(
    id: 'electric',
    title: 'Electric Shock',
    icon: Icons.electrical_services,
    description:
        'Electric shocks can cause severe burns and stop the heart. Do not touch the person if they are still in contact with the electrical source.',
    requiresEmergency: true,
    steps: [
      FirstAidStep(
        instruction:
            'Turn off the source of electricity if possible (unplug the appliance or turn off the mains).',
        imagePath: 'assets/images/first_aid/e1.png',
      ),
      FirstAidStep(
        instruction:
            'If you cannot turn off the supply, push the person away from the source using a dry, non-conducting object like a wooden broom handle.',
        imagePath: 'assets/images/first_aid/e2.png',
      ),
      FirstAidStep(
        instruction:
            'Once they are clear of the power block, call EMS immediately.',
      ),
      FirstAidStep(
        instruction:
            'Check their breathing. If they are not breathing normally, begin CPR.',
      ),
      FirstAidStep(
        instruction:
            'Treat any visible burns as severe burns (cool with water, cover with cling film).',
      ),
    ],
    dos: [
      'Ensure your own safety first.',
      'Stand on dry, insulating material (like a rubber mat or dry wood) if moving them.',
    ],
    donts: [
      'Do NOT touch the person with your bare hands while they are in contact with the current.',
      'Do NOT approach high-voltage wires; stay at least 18 meters away and call the authorities.',
    ],
  ),
  const FirstAidCategory(
    id: 'heartattack',
    title: 'Heart Attack',
    icon: Icons.favorite,
    description:
        'A heart attack occurs when the blood supply to part of the heart stops. Recognizing the signs early and calling an ambulance is critical.',
    requiresEmergency: true,
    steps: [
      FirstAidStep(
        instruction:
            'Call EMS immediately. Tell them you suspect a heart attack.',
      ),
      FirstAidStep(
        instruction:
            'Make the person comfortable. The best position is sitting on the floor, with their head and shoulders supported and their knees bent (the W position) to ease strain on the heart.',
        imagePath: 'assets/images/first_aid/heartattack_step1.png',
      ),
      FirstAidStep(
        instruction:
            'If they are conscious and not allergic, give them an adult aspirin (300mg) and tell them to slowly chew it. This thins the blood.',
      ),
      FirstAidStep(
        instruction:
            'Constantly monitor their vital signs (level of response, breathing, pulse) until help arrives.',
      ),
      FirstAidStep(
        instruction:
            'If they become unresponsive and stop breathing normally, prepare to start CPR.',
      ),
    ],
    warnings: [
      'Symptoms include persistent crushing chest pain that may spread to the arms, neck, jaw, back, or stomach, shortness of breath, sweating, and feeling faint.',
    ],
    dos: [
      'Keep the person calm and still.',
      'Loosen tight clothing around their neck and waist.',
    ],
    donts: [
      'Do NOT let them walk or exert themselves under any circumstances.',
    ],
  ),
  const FirstAidCategory(
    id: 'stroke',
    title: 'Stroke',
    icon: Icons.medical_services,
    description:
        'A stroke is a medical emergency that occurs when blood flow to the brain is cut off. Think F.A.S.T.',
    requiresEmergency: true,
    steps: [
      FirstAidStep(
        instruction:
            'Use the F.A.S.T. test:\nFace - Has their face fallen on one side? Can they smile?\nArms - Can they raise both arms and keep them there?\nSpeech - Is their speech slurred?\nTime - Time to call EMS immediately if you see any single one of these signs.',
        imagePath: 'assets/images/first_aid/f1.png',
      ),
      FirstAidStep(
        instruction: 'Call EMS immediately and tell them "Stroke".',
      ),
      FirstAidStep(
        instruction:
            'Keep the person comfortable and supported. Reassure them.',
      ),
      FirstAidStep(
        instruction:
            'If they become unresponsive but are breathing normally, place them in the recovery position.',
      ),
    ],
    dos: [
      'Note the time when the symptoms first started, this is crucial for hospital treatment.',
    ],
    donts: [
      'Do NOT give them anything to eat or drink; they may have lost the ability to swallow safely.',
    ],
  ),
];
