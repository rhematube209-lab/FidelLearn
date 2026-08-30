# -*- coding: utf-8 -*-
import json, uuid, urllib.request

questions_full = [
    # Q1
    {
        "q_num": 1,
        "text_en": "What is the locus of all points in a plane for which the sum of the distances from two fixed points is constant?",
        "text_am": "በአንድ ጠለል ላይ ከሁለት ቋሚ ነጥቦች ያለው የርቀቶች ድምር ቋሚ የሆነባቸው ነጥቦች ስብስብ ምን ይባላል?",
        "unit_id": "math_u1", "topic_id": "math_t1_1", "difficulty": "easy",
        "choices": [
            {"label": "A", "text_en": "Hyperbola", "text_am": "ሃይፐርቦላ", "is_correct": False},
            {"label": "B", "text_en": "Parabola", "text_am": "ፓራቦላ", "is_correct": False},
            {"label": "C", "text_en": "Ellipse", "text_am": "ኤሊፕስ", "is_correct": True},
            {"label": "D", "text_en": "Circle", "text_am": "ክብ", "is_correct": False}
        ],
        "explanation": {
            "solution_text_en": "1. An ellipse is defined as the locus of all points P in a plane where the sum of distances to two fixed foci F1 and F2 is constant: PF1 + PF2 = 2a.\n2. A hyperbola is the locus where the absolute difference of distances is constant (|PF1 - PF2| = 2a).\n3. A circle is the locus of points equidistant from a single fixed center.\n4. A parabola is the set of points equidistant from a fixed focus and a directrix line.\nTherefore, the correct answer is C (Ellipse).",
            "simpler_explanation_en": "Constant sum of distances from two fixed points = Ellipse.",
            "key_concept": "Geometric definition of Ellipse: PF1 + PF2 = constant.",
            "common_pitfall": "Confusing sum of distances (ellipse) with difference (hyperbola)."
        }
    },
    # Q2
    {
        "q_num": 2,
        "text_en": "The radian measure of an angle of 120° is equal to:",
        "text_am": "የ 120° አንግል የሬዲያን መለኪያ ከየትኛው ጋር እኩል ነው?",
        "unit_id": "math_u2", "topic_id": "math_t2_1", "difficulty": "easy",
        "choices": [
            {"label": "A", "text_en": "2π/3", "text_am": "2π/3", "is_correct": True},
            {"label": "B", "text_en": "4π/3", "text_am": "4π/3", "is_correct": False},
            {"label": "C", "text_en": "π/2", "text_am": "π/2", "is_correct": False},
            {"label": "D", "text_en": "π/4", "text_am": "π/4", "is_correct": False}
        ],
        "explanation": {
            "solution_text_en": "Convert degrees to radians by multiplying by π/180°:\nθ = 120° × (π / 180°) = 120π / 180 = 2π/3 radians.\nTherefore, the correct answer is A.",
            "simpler_explanation_en": "120/180 reduces to 2/3, so 120° = 2π/3.",
            "key_concept": "Radian conversion: radians = degrees × (π / 180°).",
            "common_pitfall": "Inverting the conversion factor as 180/π."
        }
    },
    # Q3
    {
        "q_num": 3,
        "text_en": "What is the surface area of a sphere with radius 6 cm?",
        "text_am": "የራዲየሱ ርዝመት 6 ሳ.ሜ የሆነ ሉል አጠቃላይ የገጽታ ስፋት ስንት ነው?",
        "unit_id": "math_u1", "topic_id": "math_t1_1", "difficulty": "easy",
        "choices": [
            {"label": "A", "text_en": "24π cm²", "text_am": "24π ሳ.ሜ²", "is_correct": False},
            {"label": "B", "text_en": "36π cm²", "text_am": "36π ሳ.ሜ²", "is_correct": False},
            {"label": "C", "text_en": "48π cm²", "text_am": "48π ሳ.ሜ²", "is_correct": False},
            {"label": "D", "text_en": "144π cm²", "text_am": "144π ሳ.ሜ²", "is_correct": True}
        ],
        "explanation": {
            "solution_text_en": "1. Surface area of a sphere formula: S = 4πr².\n2. With r = 6 cm:\nS = 4π(6²) = 4π(36) = 144π cm².\nTherefore, the correct answer is D.",
            "simpler_explanation_en": "S = 4 × π × 6² = 4 × 36 × π = 144π cm².",
            "key_concept": "Surface area of sphere = 4πr².",
            "common_pitfall": "Using circle area πr² = 36π instead of 4πr²."
        }
    },
    # Q4
    {
        "q_num": 4,
        "text_en": "Which of the following is the measure of an exterior angle of a regular 10-sided polygon (decagon)?",
        "text_am": "ባለ 10 ጎን መደበኛ ፖሊጎን የአንድ ውጫዊ አንግል ልክ ስንት ነው?",
        "unit_id": "math_u1", "topic_id": "math_t1_1", "difficulty": "easy",
        "choices": [
            {"label": "A", "text_en": "72°", "text_am": "72°", "is_correct": False},
            {"label": "B", "text_en": "144°", "text_am": "144°", "is_correct": False},
            {"label": "C", "text_en": "180°", "text_am": "180°", "is_correct": False},
            {"label": "D", "text_en": "36°", "text_am": "36°", "is_correct": True}
        ],
        "explanation": {
            "solution_text_en": "1. The sum of all exterior angles for any convex polygon is 360°.\n2. For a regular decagon (n = 10 equal sides/angles):\nExterior angle = 360° / 10 = 36°.\nTherefore, the correct answer is D.",
            "simpler_explanation_en": "Exterior angle = 360° / n = 360° / 10 = 36°.",
            "key_concept": "Exterior angle of regular n-gon = 360° / n.",
            "common_pitfall": "Calculating the interior angle (180° - 36° = 144°)."
        }
    },
    # Q5
    {
        "q_num": 5,
        "text_en": "If the volume of a right circular cone is 64π cm³ and the diameter of its base is 8 cm, what is the height of the cone?",
        "text_am": "የአንድ ቀጥተኛ ክብ ሾጣጣ ይዘት 64π ሳ.ሜ³ እና የመሰረቱ ዲያሜትር 8 ሳ.ሜ ቢሆን፣ የሾጣጣው ቁመት ስንት ነው?",
        "unit_id": "math_u1", "topic_id": "math_t1_1", "difficulty": "medium",
        "choices": [
            {"label": "A", "text_en": "4 cm", "text_am": "4 ሳ.ሜ", "is_correct": False},
            {"label": "B", "text_en": "12 cm", "text_am": "12 ሳ.ሜ", "is_correct": True},
            {"label": "C", "text_en": "8 cm", "text_am": "8 ሳ.ሜ", "is_correct": False},
            {"label": "D", "text_en": "3 cm", "text_am": "3 ሳ.ሜ", "is_correct": False}
        ],
        "explanation": {
            "solution_text_en": "1. Base radius r = diameter / 2 = 8 / 2 = 4 cm.\n2. Volume formula for a cone: V = (1/3)πr²h.\n3. Substitute values: 64π = (1/3)π(4)²h = (16/3)πh.\n4. Cancel π: 64 = 16h / 3 ⇒ 192 = 16h ⇒ h = 12 cm.\nTherefore, the correct answer is B.",
            "simpler_explanation_en": "64π = (1/3)π(16)h ⇒ 64 = 16h/3 ⇒ h = 12 cm.",
            "key_concept": "Cone volume V = 1/3 π r² h.",
            "common_pitfall": "Using diameter 8 instead of radius 4."
        }
    },
    # Q6
    {
        "q_num": 6,
        "text_en": "What are the quotient and remainder, respectively, when 75 is divided by 20?",
        "text_am": "75 ለ 20 ሲካፈል ድርሻው እና ቀሪው በቅደም ተከተል ስንት ናቸው?",
        "unit_id": "math_u1", "topic_id": "math_t1_1", "difficulty": "easy",
        "choices": [
            {"label": "A", "text_en": "3 and 15", "text_am": "3 እና 15", "is_correct": True},
            {"label": "B", "text_en": "4 and 5", "text_am": "4 እና 5", "is_correct": False},
            {"label": "C", "text_en": "15 and 3", "text_am": "15 እና 3", "is_correct": False},
            {"label": "D", "text_en": "2 and 19", "text_am": "2 እና 19", "is_correct": False}
        ],
        "explanation": {
            "solution_text_en": "By the division algorithm:\n75 = 20(3) + 15, with 0 ≤ 15 < 20.\nTherefore, the quotient is 3 and the remainder is 15 (Choice A).",
            "simpler_explanation_en": "75 / 20 = 3 with remainder 15 because 20 × 3 = 60 and 75 - 60 = 15.",
            "key_concept": "Division Algorithm: a = bq + r where 0 ≤ r < b.",
            "common_pitfall": "Reversing the order of quotient and remainder."
        }
    },
    # Q7
    {
        "q_num": 7,
        "text_en": "Given f(x) = x³ + px + 1, where f(0) and f(1) have opposite signs, which value of p can satisfy this condition?",
        "text_am": "f(x) = x³ + px + 1 ተሰጥቶ የ f(0) እና f(1) ዋጋዎች ተቃራኒ ምልክት ቢኖራቸው፣ የ p ዋጋ ከየትኞቹ አንዱ ሊሆን ይችላል?",
        "unit_id": "math_u2", "topic_id": "math_t2_2", "difficulty": "medium",
        "choices": [
            {"label": "A", "text_en": "-1", "text_am": "-1", "is_correct": False},
            {"label": "B", "text_en": "-2", "text_am": "-2", "is_correct": False},
            {"label": "C", "text_en": "1", "text_am": "1", "is_correct": False},
            {"label": "D", "text_en": "-3", "text_am": "-3", "is_correct": True}
        ],
        "explanation": {
            "solution_text_en": "1. Compute f(0): f(0) = 0³ + p(0) + 1 = 1 > 0.\n2. For f(1) to have the opposite sign, f(1) must be strictly negative (f(1) < 0).\n3. Compute f(1): f(1) = 1³ + p(1) + 1 = p + 2.\n4. Set inequality: p + 2 < 0 ⇒ p < -2.\n5. Among the values, p = -3 is strictly less than -2 (which gives f(1) = -1 < 0).\nTherefore, the correct choice is D (-3).",
            "simpler_explanation_en": "f(0) = 1 (positive). For opposite signs, f(1) = p + 2 must be negative, so p < -2. Only p = -3 works.",
            "key_concept": "Intermediate Value Theorem condition & function evaluation.",
            "common_pitfall": "Choosing p = -2, which makes f(1) = 0 (zero has no sign, not opposite sign)."
        }
    },
    # Q8
    {
        "q_num": 8,
        "text_en": "In rolling a single fair six-sided die, what is the probability of obtaining a 3 or a 5?",
        "text_am": "አንድ መደበኛ ባለ 6 ጎን ዳይስ ሲወረወር 3 ወይም 5 የማግኘት እድል ስንት ነው?",
        "unit_id": "math_u1", "topic_id": "math_t1_1", "difficulty": "easy",
        "choices": [
            {"label": "A", "text_en": "1/3", "text_am": "1/3", "is_correct": True},
            {"label": "B", "text_en": "1/4", "text_am": "1/4", "is_correct": False},
            {"label": "C", "text_en": "1/6", "text_am": "1/6", "is_correct": False},
            {"label": "D", "text_en": "1/2", "text_am": "1/2", "is_correct": False}
        ],
        "explanation": {
            "solution_text_en": "1. Sample space S = {1, 2, 3, 4, 5, 6}, total outcomes n(S) = 6.\n2. Favorable outcomes E = {3, 5}, n(E) = 2.\n3. Probability P(E) = n(E) / n(S) = 2/6 = 1/3.\nTherefore, the correct answer is A.",
            "simpler_explanation_en": "2 favorable outcomes out of 6 total = 2/6 = 1/3.",
            "key_concept": "Theoretical Probability: P(E) = favorable outcomes / total outcomes.",
            "common_pitfall": "Multiplying probabilities (1/6 × 1/6) instead of adding mutually exclusive events (1/6 + 1/6)."
        }
    },
    # Q9
    {
        "q_num": 9,
        "text_en": "Which one of the following statements is true regarding inverse trigonometric functions?",
        "text_am": "ስለ ግልባጭ ትሪጎኖሜትሪክ ፈንክሽኖች ከሚከተሉት ውስጥ እውነት የሆነው የቱ ነው?",
        "unit_id": "math_u2", "topic_id": "math_t2_1", "difficulty": "medium",
        "choices": [
            {"label": "A", "text_en": "The range of arctan(x) is [-π, π]", "text_am": "የ arctan(x) ሬንጅ [-π, π] ነው", "is_correct": False},
            {"label": "B", "text_en": "The range of arcsin(x) is (-∞, ∞)", "text_am": "የ arcsin(x) ሬንጅ (-∞, ∞) ነው", "is_correct": False},
            {"label": "C", "text_en": "The domain of arccos(x) is [-1, 1]", "text_am": "የ arccos(x) ዶሜን [-1, 1] ነው", "is_correct": True},
            {"label": "D", "text_en": "The domain of arcsin(x) is [0, π]", "text_am": "የ arcsin(x) ዶሜን [0, π] ነው", "is_correct": False}
        ],
        "explanation": {
            "solution_text_en": "1. Since -1 ≤ cos(θ) ≤ 1 for all real θ, the domain of arccos(x) is the interval [-1, 1]. Range is [0, π].\n2. The domain of arcsin(x) is [-1, 1], and its range is [-π/2, π/2].\n3. The domain of arctan(x) is (-∞, ∞), and its range is (-π/2, π/2).\nTherefore, statement C is the only true statement.",
            "simpler_explanation_en": "Cosine outputs between -1 and 1, so inverse cosine accepts inputs in [-1, 1].",
            "key_concept": "Domains and ranges of inverse trigonometric functions.",
            "common_pitfall": "Confusing the range of cos(x) with the range of arccos(x)."
        }
    },
    # Q10
    {
        "q_num": 10,
        "text_en": "The angle of depression of the top of a flagpole from the top of a building is 30°. The horizontal distance between the building and the pole is 40√3 m, and the pole is 10 m high. What is the height of the building?",
        "text_am": "ከአንድ ህንጻ ጫፍ ወደ ባንዲራ መስቀያ ጫፍ ያለው የቁልቁለት አንግል 30° ነው። በህንጻው እና በባንዲራው መካከል ያለው አግድም ርቀት 40√3 ሜትር ሲሆን፣ የባንዲራው ርዝመት 10 ሜትር ነው። የህንጻው ቁመት ስንት ነው?",
        "unit_id": "math_u2", "topic_id": "math_t2_1", "difficulty": "hard",
        "choices": [
            {"label": "A", "text_en": "20√3 m", "text_am": "20√3 ሜ", "is_correct": False},
            {"label": "B", "text_en": "10(4/√3 + 1) m", "text_am": "10(4/√3 + 1) ሜ", "is_correct": False},
            {"label": "C", "text_en": "50 m", "text_am": "50 ሜ", "is_correct": True},
            {"label": "D", "text_en": "40 m", "text_am": "40 ሜ", "is_correct": False}
        ],
        "explanation": {
            "solution_text_en": "1. Let H be the total height of the building.\n2. The top of the flagpole is at height 10 m, so the vertical difference is Δy = H - 10.\n3. The horizontal distance d = 40√3 m.\n4. Using trigonometry for angle of depression 30°:\ntan(30°) = (H - 10) / (40√3).\n5. Since tan(30°) = 1/√3:\n1/√3 = (H - 10) / (40√3) ⇒ H - 10 = 40 ⇒ H = 50 m.\nTherefore, the correct answer is C (50 m).",
            "simpler_explanation_en": "tan(30°) = 1/√3 = (H - 10)/(40√3) ⇒ H - 10 = 40 ⇒ H = 50 m.",
            "key_concept": "Angle of depression in right triangle trigonometry: tan(θ) = opposite / adjacent.",
            "common_pitfall": "Forgetting to add the 10 m flagpole height to the vertical difference."
        }
    },
    # Q11
    {
        "q_num": 11,
        "text_en": "Let R = {(x, y) : y ≥ x² + 1 and y ≤ 5}. Which relation defines the inverse relation R⁻¹?",
        "text_am": "R = {(x, y) : y ≥ x² + 1 and y ≤ 5} ቢሆን፣ የግልባጭ ዝምድናውን R⁻¹ የሚገልጸው የቱ ነው?",
        "unit_id": "math_u1", "topic_id": "math_t1_1", "difficulty": "medium",
        "choices": [
            {"label": "A", "text_en": "{(x, y) : x ≥ y² + 1 and x ≤ 5}", "text_am": "{(x, y) : x ≥ y² + 1 and x ≤ 5}", "is_correct": True},
            {"label": "B", "text_en": "{(x, y) : x ≤ y² + 1 and x ≤ 5}", "text_am": "{(x, y) : x ≤ y² + 1 and x ≤ 5}", "is_correct": False},
            {"label": "C", "text_en": "{(x, y) : x ≥ y² - 1 and x ≤ 5}", "text_am": "{(x, y) : x ≥ y² - 1 and x ≤ 5}", "is_correct": False},
            {"label": "D", "text_en": "{(x, y) : x ≤ y² - 1 and x ≤ 5}", "text_am": "{(x, y) : x ≤ y² - 1 and x ≤ 5}", "is_correct": False}
        ],
        "explanation": {
            "solution_text_en": "1. The inverse relation R⁻¹ of any relation R on ℝ is obtained by interchanging the variables x and y in its defining conditions.\n2. In R: y ≥ x² + 1 becomes x ≥ y² + 1 in R⁻¹.\n3. In R: y ≤ 5 becomes x ≤ 5 in R⁻¹.\n4. Therefore: R⁻¹ = {(x, y) : x ≥ y² + 1 and x ≤ 5}.\nTherefore, the correct answer is A.",
            "simpler_explanation_en": "Swap x and y in all inequalities: y ≥ x² + 1 becomes x ≥ y² + 1, and y ≤ 5 becomes x ≤ 5.",
            "key_concept": "Inverse of a relation R: R⁻¹ = {(y, x) : (x, y) ∈ R}.",
            "common_pitfall": "Attempting algebraic subtraction instead of simply swapping coordinates x and y."
        }
    },
    # Q12
    {
        "q_num": 12,
        "text_en": "Given matrices A = [2 0 5; 3 1 4; 0 6 -2] and B = [1 3 0; 6 5 2; 9 7 0], which matrix represents A - B?",
        "text_am": "ማትሪክስ A = [2 0 5; 3 1 4; 0 6 -2] እና B = [1 3 0; 6 5 2; 9 7 0] ቢሆኑ፣ A - B የሚሆነው የቱ ነው?",
        "unit_id": "math_u1", "topic_id": "math_t1_1", "difficulty": "medium",
        "choices": [
            {"label": "A", "text_en": "[1 3 5; -3 -4 2; 9 1 2]", "text_am": "[1 3 5; -3 -4 2; 9 1 2]", "is_correct": False},
            {"label": "B", "text_en": "[1 -3 -5; -3 -4 2; 9 1 2]", "text_am": "[1 -3 -5; -3 -4 2; 9 1 2]", "is_correct": False},
            {"label": "C", "text_en": "[1 3 5; -3 -4 -2; -9 1 2]", "text_am": "[1 3 5; -3 -4 -2; -9 1 2]", "is_correct": False},
            {"label": "D", "text_en": "[1 -3 5; -3 -4 2; -9 -1 -2]", "text_am": "[1 -3 5; -3 -4 2; -9 -1 -2]", "is_correct": True}
        ],
        "explanation": {
            "solution_text_en": "Subtract corresponding entries (A - B)ij = Aij - Bij:\nRow 1: [2-1, 0-3, 5-0] = [1, -3, 5]\nRow 2: [3-6, 1-5, 4-2] = [-3, -4, 2]\nRow 3: [0-9, 6-7, -2-0] = [-9, -1, -2]\nCombining these rows yields: [1 -3 5; -3 -4 2; -9 -1 -2].\nTherefore, the correct answer is D.",
            "simpler_explanation_en": "Subtract each element: Row 1 is (1, -3, 5), Row 2 is (-3, -4, 2), Row 3 is (-9, -1, -2).",
            "key_concept": "Matrix subtraction element by element.",
            "common_pitfall": "Sign errors when subtracting negative numbers or zero."
        }
    },
    # Q13
    {
        "q_num": 13,
        "text_en": "Starting at the origin (0, 0, 0), move 5 units along the negative x-axis, 5 units along the positive y-axis, and 5 units along the negative z-axis. What are the coordinates of the final point?",
        "text_am": "ከመነሻ ነጥብ (0, 0, 0) በመነሳት፣ 5 ዩኒት በአሉታዊ x-ዘንግ፣ 5 ዩኒት በአዎንታዊ y-ዘንግ፣ እና 5 ዩኒት በአሉታዊ z-ዘንግ ቢጓዝ የመጨረሻው ነጥብ ኮኦርዲኔት ስንት ይሆናል?",
        "unit_id": "math_u1", "topic_id": "math_t1_1", "difficulty": "easy",
        "choices": [
            {"label": "A", "text_en": "(5, 5, 5)", "text_am": "(5, 5, 5)", "is_correct": False},
            {"label": "B", "text_en": "(-5, 5, -5)", "text_am": "(-5, 5, -5)", "is_correct": True},
            {"label": "C", "text_en": "(5, -5, -5)", "text_am": "(5, -5, -5)", "is_correct": False},
            {"label": "D", "text_en": "(-5, -5, 5)", "text_am": "(-5, -5, 5)", "is_correct": False}
        ],
        "explanation": {
            "solution_text_en": "1. Negative x-axis motion by 5: x = 0 - 5 = -5.\n2. Positive y-axis motion by 5: y = 0 + 5 = 5.\n3. Negative z-axis motion by 5: z = 0 - 5 = -5.\n4. Resulting coordinate is (-5, 5, -5).\nTherefore, the correct answer is B.",
            "simpler_explanation_en": "(-5 in x, +5 in y, -5 in z) = (-5, 5, -5).",
            "key_concept": "3D Cartesian coordinate system.",
            "common_pitfall": "Mixing signs for positive vs negative directions."
        }
    },
    # Q14
    {
        "q_num": 14,
        "text_en": "Which one of the following physical quantities is a vector quantity?",
        "text_am": "ከሚከተሉት መጠኖች ውስጥ ቬክተር (vector quantity) የሆነው የቱ ነው?",
        "unit_id": "math_u1", "topic_id": "math_t1_1", "difficulty": "easy",
        "choices": [
            {"label": "A", "text_en": "Weight of an object", "text_am": "የአንድ አካል ክብደት (Weight)", "is_correct": True},
            {"label": "B", "text_en": "Speed of a motorbike", "text_am": "የሞተር ሳይክል ፍጥነት (Speed)", "is_correct": False},
            {"label": "C", "text_en": "Volume of a box", "text_am": "የሳጥን ይዘት (Volume)", "is_correct": False},
            {"label": "D", "text_en": "Width of a bedroom", "text_am": "የመኝታ ክፍል ወርድ (Width)", "is_correct": False}
        ],
        "explanation": {
            "solution_text_en": "1. A vector quantity possesses both magnitude and directional orientation.\n2. Weight is gravitational force (W = mg), which has magnitude and points downward toward Earth's center of mass.\n3. Speed, volume, and width have only magnitude (scalars).\nTherefore, the correct answer is A (Weight).",
            "simpler_explanation_en": "Weight is a force with direction (downward) = Vector.",
            "key_concept": "Vectors vs Scalars: Vectors have magnitude and direction.",
            "common_pitfall": "Confusing mass (scalar) with weight (vector force)."
        }
    },
    # Q15
    {
        "q_num": 15,
        "text_en": "Which one of the following is the first derivative f'(x) of the function f(x) = tan(x) + 3ˣ?",
        "text_am": "የፈንክሽን f(x) = tan(x) + 3ˣ የመጀመሪያ ዲሪቬቲቭ f'(x) የቱ ነው?",
        "unit_id": "math_u2", "topic_id": "math_t2_2", "difficulty": "medium",
        "choices": [
            {"label": "A", "text_en": "sec²(x) + 3ˣ ln(3)", "text_am": "sec²(x) + 3ˣ ln(3)", "is_correct": True},
            {"label": "B", "text_en": "-csc²(x) + 3ˣ ln(3)", "text_am": "-csc²(x) + 3ˣ ln(3)", "is_correct": False},
            {"label": "C", "text_en": "-tan(x) + 3ˣ ln(3)", "text_am": "-tan(x) + 3ˣ ln(3)", "is_correct": False},
            {"label": "D", "text_en": "sec²(x) + 3ˣ", "text_am": "sec²(x) + 3ˣ", "is_correct": False}
        ],
        "explanation": {
            "solution_text_en": "1. Differentiate term by term:\n- d/dx [tan(x)] = sec²(x)\n- d/dx [aˣ] = aˣ ln(a), so d/dx [3ˣ] = 3ˣ ln(3)\n2. Adding the derivatives: f'(x) = sec²(x) + 3ˣ ln(3).\nTherefore, the correct answer is A.",
            "simpler_explanation_en": "Derivative of tan(x) is sec²(x), and derivative of 3ˣ is 3ˣ ln(3).",
            "key_concept": "Derivatives of trigonometric and exponential functions: d/dx(aˣ) = aˣ ln(a).",
            "common_pitfall": "Forgetting the ln(3) factor when differentiating 3ˣ."
        }
    },
    # Q16
    {
        "q_num": 16,
        "text_en": "Which point lies inside the sphere x² + y² + z² = 5?",
        "text_am": "በሉል x² + y² + z² = 5 ውስጥ የሚገኘው ነጥብ የቱ ነው?",
        "unit_id": "math_u1", "topic_id": "math_t1_1", "difficulty": "easy",
        "choices": [
            {"label": "A", "text_en": "(1, -2, 2)", "text_am": "(1, -2, 2)", "is_correct": False},
            {"label": "B", "text_en": "(1, 1, 1)", "text_am": "(1, 1, 1)", "is_correct": True},
            {"label": "C", "text_en": "(1, 2, 3)", "text_am": "(1, 2, 3)", "is_correct": False},
            {"label": "D", "text_en": "(0, -2, 3)", "text_am": "(0, -2, 3)", "is_correct": False}
        ],
        "explanation": {
            "solution_text_en": "A point (x, y, z) lies strictly inside the sphere centered at the origin of radius √5 when x² + y² + z² < 5.\n- For (1, -2, 2): 1² + (-2)² + 2² = 1 + 4 + 4 = 9 > 5 (outside)\n- For (1, 1, 1): 1² + 1² + 1² = 1 + 1 + 1 = 3 < 5 (inside)\n- For (1, 2, 3): 1 + 4 + 9 = 14 > 5 (outside)\n- For (0, -2, 3): 0 + 4 + 9 = 13 > 5 (outside)\nTherefore, the point inside is B (1, 1, 1).",
            "simpler_explanation_en": "1² + 1² + 1² = 3, which is less than 5, so (1, 1, 1) is inside the sphere.",
            "key_concept": "Equation of a sphere: Interior region is x² + y² + z² < r².",
            "common_pitfall": "Testing against √5 instead of 5 (r²)."
        }
    },
    # Q17
    {
        "q_num": 17,
        "text_en": "Which one of the following gives the trigonometric (polar) form of the complex number z = 2 - 2√3 i?",
        "text_am": "የኮምፕሌክስ ቁጥር z = 2 - 2√3 i ትሪጎኖሜትሪክ (ፖላር) ፎርም የቱ ነው?",
        "unit_id": "math_u1", "topic_id": "math_t1_1", "difficulty": "medium",
        "choices": [
            {"label": "A", "text_en": "4(cos(5π/3) + i sin(5π/3))", "text_am": "4(cos(5π/3) + i sin(5π/3))", "is_correct": True},
            {"label": "B", "text_en": "4(cos(4π/3) + i sin(4π/3))", "text_am": "4(cos(4π/3) + i sin(4π/3))", "is_correct": False},
            {"label": "C", "text_en": "4(cos(3π/4) + i sin(3π/4))", "text_am": "4(cos(3π/4) + i sin(3π/4))", "is_correct": False},
            {"label": "D", "text_en": "4(cos(π/3) + i sin(π/3))", "text_am": "4(cos(π/3) + i sin(π/3))", "is_correct": False}
        ],
        "explanation": {
            "solution_text_en": "1. Modulus: r = √(x² + y²) = √(2² + (-2√3)²) = √(4 + 12) = √16 = 4.\n2. Argument: Since x = 2 > 0 and y = -2√3 < 0, z is in Quadrant IV.\n3. Reference angle θ_ref = arctan(|-2√3| / 2) = arctan(√3) = π/3 (or 60°).\n4. In Quadrant IV: θ = 2π - π/3 = 5π/3 (or 300°).\n5. Polar form: z = r(cos θ + i sin θ) = 4(cos(5π/3) + i sin(5π/3)).\nTherefore, the correct answer is A.",
            "simpler_explanation_en": "r = √(4+12) = 4. Angle in Q4 with tan θ = -√3 is 5π/3. Form is 4(cos(5π/3) + i sin(5π/3)).",
            "key_concept": "Polar form of complex numbers: z = r(cos θ + i sin θ).",
            "common_pitfall": "Choosing an argument in Quadrant II (2π/3) instead of Quadrant IV (5π/3)."
        }
    },
    # Q18
    {
        "q_num": 18,
        "text_en": "If vector a = (4, 3, 2) and vector b = (1, 2, -3), which vector statement is NOT correct?",
        "text_am": "ቬክተር a = (4, 3, 2) እና b = (1, 2, -3) ቢሆኑ፣ ትክክል ያልሆነው አረፍተ ነገር የቱ ነው?",
        "unit_id": "math_u1", "topic_id": "math_t1_1", "difficulty": "medium",
        "choices": [
            {"label": "A", "text_en": "a + b = (5, 5, -1)", "text_am": "a + b = (5, 5, -1)", "is_correct": False},
            {"label": "B", "text_en": "a + 2b = (6, 7, -4)", "text_am": "a + 2b = (6, 7, -4)", "is_correct": False},
            {"label": "C", "text_en": "b - a = (-3, -1, -5)", "text_am": "b - a = (-3, -1, -5)", "is_correct": False},
            {"label": "D", "text_en": "a - 2b = (2, 1, 8)", "text_am": "a - 2b = (2, 1, 8)", "is_correct": True}
        ],
        "explanation": {
            "solution_text_en": "Compute each operation:\n- a + b = (4+1, 3+2, 2-3) = (5, 5, -1) (Correct)\n- a + 2b = (4+2, 3+4, 2-6) = (6, 7, -4) (Correct)\n- b - a = (1-4, 2-3, -3-2) = (-3, -1, -5) (Correct)\n- a - 2b = (4 - 2(1), 3 - 2(2), 2 - 2(-3)) = (4-2, 3-4, 2+6) = (2, -1, 8).\nChoice D gives (2, 1, 8) with the middle component +1 instead of -1, so statement D is incorrect.\nTherefore, the answer is D.",
            "simpler_explanation_en": "a - 2b = (4-2, 3-4, 2+6) = (2, -1, 8). Statement D says (2, 1, 8), which is false.",
            "key_concept": "Linear combinations of vectors in ℝ³.",
            "common_pitfall": "Sign error in subtracting 2(2) from 3: 3 - 4 = -1, not +1."
        }
    },
    # Q19
    {
        "q_num": 19,
        "text_en": "What is the product of the complex numbers z = 2 - 3i and w = 5 + 2i?",
        "text_am": "የኮምፕሌክስ ቁጥሮች z = 2 - 3i እና w = 5 + 2i ብዜት ስንት ነው?",
        "unit_id": "math_u1", "topic_id": "math_t1_1", "difficulty": "easy",
        "choices": [
            {"label": "A", "text_en": "16 + 11i", "text_am": "16 + 11i", "is_correct": False},
            {"label": "B", "text_en": "4 - 11i", "text_am": "4 - 11i", "is_correct": False},
            {"label": "C", "text_en": "16 - 11i", "text_am": "16 - 11i", "is_correct": True},
            {"label": "D", "text_en": "29", "text_am": "29", "is_correct": False}
        ],
        "explanation": {
            "solution_text_en": "Use the distributive property (FOIL):\n(2 - 3i)(5 + 2i) = 2(5) + 2(2i) - 3i(5) - 3i(2i)\n= 10 + 4i - 15i - 6i².\nSince i² = -1:\n-6i² = -6(-1) = +6.\nCombining real and imaginary parts:\n(10 + 6) + (4 - 15)i = 16 - 11i.\nTherefore, the correct answer is C.",
            "simpler_explanation_en": "(2-3i)(5+2i) = 10 + 4i - 15i - 6(-1) = 16 - 11i.",
            "key_concept": "Complex number multiplication using i² = -1.",
            "common_pitfall": "Treating -6i² as -6 instead of +6."
        }
    },
    # Q20
    {
        "q_num": 20,
        "text_en": "Which statement is true regarding the arithmetic mean of a data set?",
        "text_am": "ስለ አንድ የዳታ ስብስብ አርቲሜቲክ ሚን (arithmetic mean) እውነት የሆነው የቱ ነው?",
        "unit_id": "math_u1", "topic_id": "math_t1_1", "difficulty": "easy",
        "choices": [
            {"label": "A", "text_en": "It is affected by extreme values (outliers)", "text_am": "በጣም ትላልቅ ወይም ትናንሽ ቁጥሮች (outliers) ተጽዕኖ ይደርስበታል", "is_correct": True},
            {"label": "B", "text_en": "There can be two means for the same data set", "text_am": "ለአንድ ዳታ ሁለት ሚኖች ሊኖሩ ይችላሉ", "is_correct": False},
            {"label": "C", "text_en": "It can be used directly for qualitative data", "text_am": "ለጥራት መረጃ (qualitative data) በቀጥታ ይሰላል", "is_correct": False},
            {"label": "D", "text_en": "It can always be found when some values are missing", "text_am": "የጎደሉ ቁጥሮች ቢኖሩም ሁልጊዜ ማግኘት ይቻላል", "is_correct": False}
        ],
        "explanation": {
            "solution_text_en": "1. The arithmetic mean (x̄ = Σx / n) incorporates every single numerical observation in its sum.\n2. Consequently, extreme high or low values (outliers) disproportionately shift the mean.\n3. The mean is always uniquely defined (cannot have two means), applies only to quantitative data, and requires all values.\nTherefore, the correct answer is A.",
            "simpler_explanation_en": "The mean uses all values, so high or low outliers pull the average up or down.",
            "key_concept": "Properties of measures of central tendency (Mean vs Median).",
            "common_pitfall": "Confusing the mean with the mode (which can have multiple values / bimodal)."
        }
    }
]

print(f"Loaded {len(questions_full)} questions so far.")
