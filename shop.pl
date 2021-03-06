#!/usr/bin/perl -w

## Copyright (C) 2001 Faried Nawaz

## Author: Faried Nawaz <fn@hungry.org>
## Maintainer: fn@hungry.org
## Keywords: games
## Created: 2001-07-30

## $Id$

## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2, or (at your option)
## any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; if not, you can either send email to this
## program's maintainer or write to: The Free Software Foundation,
## Inc.; 59 Temple Place, Suite 330; Boston, MA 02111-1307, USA.

### Commentary:

## This program is a reimplementation of some great elisp written by
## Noah Friedman, which itself was a reimplementation of some C code
## written by Brian Rice in 1989.

### Code:


use Carp;
use strict;

my @shop_adjectives =
  (
   "Arab-Israeli", "Arctic", "Asiatic", "Atlantic", "Baltic", "Braille",
   "Buy & Break", "Byronic", "Catholic", "Celtic", "Cenozoic", "Chinese",
   "Cretaceous", "Dad & Lad", "Dan Rather", "E-Z-Grip", "Gaelic", "Icelandic",
   "Johnny-come-lately", "Maoist", "Marxist", "Mesozoic", "Mexican", "Miltonic",
   "Mix 'n' Match", "Mrs. Leland's", "Napoleonic", "Naugahyde", "No-action",
   "Olympic", "Poppin-Fresh", "Portuguese", "Prenatal", "Puddle-Off!",
   "Reddy-Mix", "Ripe 'n' Sweet", "Samsonite", "Scratch 'n' Snot",
   "Strike & Spare", "Teutonic", "Wax & Wear", "aberrant", "abhorrent",
   "abrupt", "absent", "absorbent", "abstinent", "abundant", "academic",
   "achievement-oriented", "acidic", "acoustic", "acrobatic", "adamant",
   "adolescent", "adulterous", "advantageous", "adventurous", "aerobic",
   "aerodynamic", "aeronautical", "aesthetic", "affluent", "agnostic",
   "air-conditioned", "alcoholic", "algebraic", "allegorical", "allergic",
   "alphabetic", "amber", "ambidextrous", "ambient", "ambiguous", "ambitious",
   "ambivalent", "amorphous", "amphibious", "amusing", "anachronistic",
   "anaerobic", "analytical", "anarchic", "anatomic", "ancient", "androgynous",
   "angelic", "anomalous", "anonymous", "antagonistic", "anthropomorphic",
   "anti-shock", "antic", "antiperspirant", "anxious", "apathetic", "apocalyptic",
   "apologetic", "aquatic", "archaic", "ardent", "arduous", "aristocratic",
   "aromatic", "arrogant", "ascetic", "assiduous", "astigmatic",
   "astronautical", "astronomical", "asymmetrical", "asynchronous", "athletic",
   "atmospheric", "atomic", "atrocious", "atypical", "audacious", "auspicious",
   "authentic", "autistic", "autocratic", "automated", "automatic",
   "automotive", "autonomous", "avaricious", "awkward", "axiomatic", "barbaric",
   "barbarous", "barking", "barometric", "basic", "beatific", "beauteous",
   "belligerent", "benevolent", "bent", "bestial", "bicentennial", "big",
   "biochemical", "blasphemous", "blatant", "bloated", "blunt", "boisterous",
   "bombastic", "boring", "botanical", "bouffant", "bucolic", "bumptious",
   "buoyant", "bureaucratic", "burnt", "burrowing", "cackling", "cadaverous",
   "cagey", "calamitous", "callous", "cancerous", "capacious", "capricious",
   "capsized", "carbonated", "carcinogenic", "cataclysmic", "catalytic",
   "catastrophic", "catatonic", "categorical", "caustic", "cautious",
   "cavernous", "celebrity", "ceramic", "ceremonious", "cervical", "chaotic",
   "characteristic", "charismatic", "cheesy", "chemical", "chic", "chimerical",
   "chivalrous", "chromatic", "chronic", "cinematic", "circuitous", "circular",
   "civic", "civil", "clairvoyant", "classic", "classical", "claustrophobic",
   "clerical", "climactic", "clinical", "cogent", "cognizant", "coherent",
   "comical", "commodious", "communal", "competent", "complacent",
   "complaisant", "compliant", "concentric", "concomitant", "concurrent",
   "condo-conscious", "confusing", "conical", "coniferous", "conscientious",
   "conscious", "consistent", "conspicuous", "constant", "contagious",
   "contemptuous", "continuous", "convalescent", "convenient", "cooking",
   "copious", "corpulent", "cosmetic", "cosmic", "coughing", "courageous",
   "courteous", "credulous", "cretinous", "critical", "cryogenic", "cryptic",
   "cubical", "curious", "curvaceous", "cylindrical", "cynical", "dangerous",
   "dark", "deboned", "decadent", "decorator", "deep-fried", "defiant",
   "deficient", "delicious", "delinquent", "delirious", "democratic",
   "demonic", "deodorant", "deoxyribonucleic", "dependent", "despondent",
   "despotic", "detrimental", "deviant", "devious", "dexterous", "diabetic",
   "diabolical", "diagnostic", "diaphanous", "dicey", "didactic", "dietetic",
   "different", "diffident", "diligent", "diplomatic", "disastrous",
   "disheveled", "disorienting", "dissident", "dissonant", "distant",
   "distracted", "dogmatic", "domestic", "dormant", "dramatic", "drastic",
   "dubious", "dynamic", "dynastic", "dyno-blast", "dysfunctional",
   "dyspeptic", "ebullient", "eccentric", "ecclesiastical", "eclectic",
   "economical", "ecstatic", "educated", "efficient", "egocentric",
   "egregious", "elastic", "electric", "electronic", "elegant", "elevated",
   "elliptical", "eloquent", "embryonic", "eminent", "emphatic", "enchained",
   "enchanted", "encyclopedic", "energetic", "enigmatic", "enormous",
   "enthusiastic", "envious", "epic", "epileptic", "erotic", "errant",
   "erratic", "erroneous", "esoteric", "ethical", "eugenic", "euphoric",
   "evangelical", "excellent", "exorbitant", "exotic", "expandable",
   "expectant", "expeditious", "experimental", "extemporaneous",
   "extracurricular", "extraneous", "extravagant", "exuberant", "fabulous",
   "facetious", "fallacious", "famous", "fanatical", "fancy", "fantastic",
   "fastidious", "fat", "fatuous", "felicitous", "felonious", "fencing",
   "fermented", "ferocious", "fervent", "fibrous", "fictitious", "flagrant",
   "flamboyant", "flammable", "flatulent", "flippant", "flirtatious", "fluent",
   "fluorescent", "flying", "forensic", "fragrant", "frantic", "fraudulent",
   "frenetic", "fresh-frozen", "frilly", "frivolous", "frothy",
   "fuel-injected", "furious", "galactic", "gallant", "garden-variety",
   "garrulous", "gaseous", "gaunt", "gelatinous", "generic", "generous",
   "geopolitical", "geriatric", "giant", "gigantic", "glamorous", "gloating",
   "global", "glorious", "golden", "gorgeous", "gracious", "grammatical",
   "grandiloquent", "graphic", "gratuitous", "gregarious", "grievous",
   "gripping", "groundless", "gubernatorial", "gymnastic", "handy",
   "hard-core", "hardy", "harmonic", "harmonious", "harried", "hasty",
   "hazardous", "hectic", "helium-sucking", "hemispherical", "heretical",
   "heroic", "hesitant", "heterogeneous", "hideous", "hierarchical",
   "hieroglyphic", "hilarious", "historic", "histrionic", "hobnobbing",
   "homestyle", "homogeneous", "horn-rimmed", "horrendous", "hot", "hot pink",
   "humiliated", "humorous", "hurtling", "hydraulic", "hydroelectric",
   "hyperbolical", "hypnotic", "hypocritical", "hypothetical", "hysterical",
   "idiosyncratic", "idiotic", "idyllic", "igneous", "ignominious", "ignorant",
   "illogical", "illustrious", "impatient", "imperious", "impertinent",
   "impervious", "impetuous", "impious", "important", "imported", "impotent",
   "impractical", "imprudent", "impudent", "inadvertent", "inauspicious",
   "incandescent", "incautious", "incessant", "incestuous", "inclement",
   "incoherent", "incompetent", "incongruous", "inconsistent",
   "inconspicuous", "inconstant", "inconvenient", "incredulous", "incumbent",
   "indecent", "independent", "indifferent", "indigenous", "indigent",
   "indignant", "indolent", "indulgent", "industrious", "inefficient",
   "inelastic", "inelegant", "infamous", "infant", "infectious", "ingenious",
   "ingenuous", "inglorious", "inharmonious", "iniquitous", "injudicious",
   "injured", "injurious", "innocent", "inorganic", "inquisitive", "insidious",
   "insignificant", "insipid", "insistent", "insolent", "insouciant",
   "instant", "instantaneous", "insufficient", "intelligent", "intergalactic",
   "interlocking", "intermittent", "intolerant", "intoxicating",
   "intransigent", "intravenous", "intrinsic", "introductory", "intrusive",
   "inundated", "invidious", "ironic", "irrelevant", "irreverent",
   "irritating", "jealous", "jellied", "joyous", "jubilant", "judicious",
   "juvenile", "labio-palatal", "laborious", "lackadaisical", "lascivious",
   "latent", "left-handed", "lenient", "lesser-known", "libelous",
   "libidinous", "licentious", "lightweight", "lily-livered", "lingering",
   "linty", "liquid-center", "litigious", "logical", "long-playing",
   "loquacious", "lousy", "lubricating", "lubricious", "lucky", "ludicrous",
   "luminescent", "luminous", "lunar", "lunatic", "luscious", "lustrous",
   "luxuriant", "luxurious", "lyrical", "magical", "magisterial",
   "magnanimous", "magnetic", "magnificent", "majestic", "malcontent",
   "malevolent", "malicious", "malignant", "maniacal", "marvelous",
   "maternity", "mathematical", "mauve", "mechanical", "medical", "melodic",
   "melodious", "melodramatic", "mendacious", "menstruating", "meretricious",
   "meritorious", "metallic", "metaphorical", "meteoritic", "methodical",
   "meticulous", "metric", "midget", "mighty", "migrant", "militant",
   "miraculous", "misanthropic", "miscellaneous", "mischievous",
   "misdirected", "missing", "momentous", "monarchical", "monogamous",
   "monotonous", "monstrous", "mountainous", "multitudinous", "murderous",
   "muscular", "musical", "mutant", "myopic", "mysterious", "mystic",
   "mythical", "nebulous", "negligent", "neoclassical", "nervous", "neurotic",
   "nice", "non-reloading", "nonchalant", "nonsensical", "nostalgic", "nosy",
   "notorious", "noxious", "nuclear", "numerical", "numerous", "nutritious",
   "nylon", "obedient", "oblivious", "obnoxious", "obsequious", "observant",
   "obsolescent", "obvious", "odious", "odorous", "officious", "oligarchical",
   "ominous", "omnipotent", "omnipresent", "omniscient", "onerous",
   "optimistic", "opulent", "oratorical", "organic", "orgiastic", "ornery",
   "orthodontic", "ostentatious", "outrageous", "paradoxical", "parasitic",
   "parenthetical", "parliamentary", "parsimonious", "partial", "pasty-faced",
   "pathetic", "patriotic", "pedantic", "pelvic", "pendulous", "penile",
   "peppermint", "perfidious", "perilous", "periodical", "permanent",
   "pernicious", "persistent", "perspicacious", "persuasive", "petrified",
   "petulant", "pharmaceutical", "philanthropic", "philosophical",
   "phosphorescent", "photogenic", "physical", "pink", "pious", "piteous",
   "planetary", "plastic", "platonic", "pleasant", "pleasing", "pliant",
   "pneumatic", "poetic", "poignant", "poisonous", "polemical", "political",
   "polyandrous", "polygynous", "pompous", "ponderous", "populous", "porous",
   "portentous", "postdoctoral", "posthumous", "pragmatic", "precarious",
   "precious", "precocious", "pregnant", "prehistoric", "preposterous",
   "presidential", "prestigious", "presumptuous", "pretentious", "prevalent",
   "previous", "problematic", "prodigious", "proficient", "projectile", "prolific",
   "prominent", "promiscuous", "prophetic", "propitious", "prosaic",
   "prosperous", "prosthetic", "prototypical", "prudent", "prurient",
   "psychiatric", "psychic", "psychotic", "pubescent", "public", "puerile",
   "pulmonary", "pulsing", "pungent", "puritanical", "pyrotechnical", "quaint",
   "quaking", "querulous", "quixotic", "quizzical", "radiant", "radioactive",
   "rain-making", "rampant", "rancorous", "rapacious", "raucous", "ravenous",
   "rebellious", "recalcitrant", "recoilless", "recreational", "recurrent",
   "red-winged", "redundant", "regimented", "relevant", "religious",
   "reluctant", "reminiscent", "remote", "repellent", "repentant",
   "repetitious", "repressed", "repugnant", "resentful", "resilient",
   "resonant", "respectable", "resplendent", "responsible", "resurgent",
   "reticent", "reverent", "revised", "rhapsodical", "rhetorical", "rheumatic",
   "rhythmic", "ridiculous", "righteous", "rigorous", "riotous", "risque",
   "river-toweling", "romantic", "rudimentary", "ruinous", "ruminant",
   "ruminating", "runcible", "rustic", "sacrilegious", "sagacious",
   "salacious", "salubrious", "sanctimonious", "sarcastic", "sardonic",
   "satanic", "satirical", "savage", "scandalous", "scanty", "scary", "scenic",
   "scented", "schizophrenic", "scholastic", "scientific", "scornful",
   "scrumptious", "scrupulous", "scurrilous", "secret", "seditious", "seismic",
   "self-propelled", "sensual", "sensuous", "sentimental", "serendipitous",
   "serious", "sexy", "shallow", "significant", "silent", "simplistic",
   "simultaneous", "sinuous", "skeptical", "skid-proof", "slanderous",
   "slanty-wise", "so-called", "solar-frightened", "solicitous", "sonorous",
   "sophomoric", "space", "spacious", "spastic", "spearmint", "special",
   "specious", "spherical", "spontaneous", "sporadic", "spurious", "squinty",
   "stagnant", "starboard", "state-supported", "static", "sticky",
   "stimulating", "stoic", "strategic", "strenuous", "studious", "stupendous",
   "subatomic", "subservient", "sudsing", "sulfurous", "sullen", "sumptuous",
   "sunburnt", "supercilious", "superfluous", "superstitious", "surfing",
   "surreptitious", "suspicious", "symbiotic", "symbolical", "symmetrical",
   "sympathetic", "symphonic", "syncopated", "synonymous", "tabular",
   "talented", "tedious", "telepathic", "televised", "tempestuous",
   "tenacious", "tenuous", "terrific", "therapeutic", "thieving", "throwaway",
   "thunderous", "titanic", "tolerant", "topical", "torrential", "tortuous",
   "toxic", "tragic", "tragicomical", "traitorous", "trans-Atlantic",
   "transient", "translucent", "transoceanic", "transparent", "transplanted",
   "traumatic", "treacherous", "treasonous", "tremendous", "tremulous",
   "trenchant", "triumphant", "tropical", "tumultuous", "turbulent", "two-way",
   "typical", "tyrannical", "ubiquitous", "unanimous", "unforgivable",
   "unhappy", "uninteresting", "unopened", "unreliable", "uproarious",
   "urgent", "vacant", "vacationing", "vacuous", "vainglorious", "valiant",
   "various", "vehement", "venomous", "vibrant", "vicarious", "vicious",
   "victorious", "vigilant", "vigorous", "villainous", "violent", "virtuous",
   "virulent", "viscous", "vitriolic", "vivacious", "vociferous", "volcanic",
   "voluminous", "voluptuous", "voracious", "watery", "weary", "welding", "wet",
   "whimsical", "wine-making", "winged", "wishy-washy", "wondrous", "would-be",
   "wry", "zealous"
  );

my @shop_nouns =
  (
   ["Budweiser", "buds"], ["Garden Weasel"],
   ["Johnny Carson", "Johnny Carson lookalikes"], "L'eggs", ["ablution"],
   ["abolition", "abolitionists"], ["abrasion", "bruisers"],
   ["absorption", "absorbers"], ["abstention", "tee-totallers"],
   ["accordion"], ["accusation", "accusers"], "acne", ["adhesive"],
   ["admonition", "admonishers"], ["aggression", "aggressors"], "aluminum",
   "ambition", "ammunition", ["animal"], ["annoyer"], ["ant"], ["apparition"],
   "approval", ["argumentation", "arguments"], ["artery", "ies", -1], ["ash", "es"],
   ["aspersion"], ["assumption"], "attention", ["auction"], ["audition"],
   ["ax", "es"], "bacon", ["bag lunch", "es"], ["bag"], ["ball"], ["basket"],
   ["battalion"], ["beagle"], ["bear"], ["bee"], "beef", ["benediction"],
   ["bird"], ["bog"], ["bomb", "defusers"], ["bracelet"], "bread", "breath",
   ["breeze"], ["bride"], ["brief"], "brunch", ["bug"], ["bum"], ["burger"],
   ["button"], "cancer", ["capture", "captors"], ["card"], ["carnation"],
   "carrion", ["casino"], "caution", ["cave"], ["chain"], ["champion"],
   ["chase", "rs"], ["cheese"], "chocolate", "chowder", ["circumcision"],
   ["circumlocution"], ["citation"], ["clasp"], ["climate"],
   ["clothing", "clothes"], ["collision", "colliders"], ["collision"],
   "combustion", ["commander"], ["commendation"], ["commission"],
   ["commotion"], ["communion"], ["companion"], ["compass", "es"], "compassion",
   ["competition", "competitors"], ["complex", "complicators"],
   ["component", "ingredients"], ["compression", "compressors"],
   ["compulsion"], ["concussion"], ["condensation", "condensers"],
   ["condiment"], ["confession"], ["configuration"],
   ["confirmation", "confirmers"], ["confrontation"], "confusion",
   "congestion", ["connotation"], "consolation", ["console"],
   ["consumption", "consumers"], ["contraception", "contraceptives"],
   ["contraption"], ["contribution"], ["convulsion"], ["coolant"],
   "corruption", ["cotillion"], ["cow"], ["crossword"], ["cushion"],
   ["dandelion"], "deception", ["delusion"], "demolition", ["departure"],
   ["depression"], ["derision", "deriders"], ["destroyer"],
   ["detection", "detectors"], "detention", ["detergent"], ["devotion"],
   "dice", ["digression"], ["direction"], "dirt", ["distemper", "distenders"],
   ["distinguisher"], ["division", "dividers"], ["dock"], ["document"],
   ["dog"], ["dogboy"], ["dwarf", "dwarves"], "ecstasy", ["effluent"], ["egg"],
   ["eggplant"], ["emission"], ["emotion"], ["enema"], "erosion", ["eruption"],
   ["excitement"], ["exclamation"], ["exclusion"], "exhaust", ["exhibition"],
   ["expectation"], ["expectorant"], ["explosion"], ["expulsion"],
   ["face", "ers"], ["fashion"], "fiction", ["finger"], "fission", ["flake"],
   ["flange"], ["flossbag"], ["flotation", "floats"], "food", "friction",
   ["frivolity", "cheater-hawks"], "fruit", ["fugitive"], "furniture",
   ["gasket"], ["ghost-melt"],
   ["glove"], ["goat"], ["goiter", "fads"], "gold", ["gong"], ["goose", "geese"],
   "gravy", ["griddle"], "grief", "guilt", "gumption", "hair", ["hamster-lip"],
   ["hand"], ["harmony", "harmonizers"], "hatred", "hay", ["helmet"], ["hider"],
   ["holiday"], "honey", ["honk", "ers"], ["hootenanny", "ies", -1], "horsie",
   ["hydrant"], ["ignition"], ["illusion"], ["immunization"], ["import"],
   ["imposition"], ["incantation"], "indigestion", ["infestation"],
   ["inflammation"], ["inhibition"], "ink", ["inquisition"], ["insect"],
   ["insurgent"], ["interruption"], ["intrusion"], ["invasion"],
   ["inversion"], ["itinerant"], ["jungle"], ["ladder"], ["laser"], "laughter",
   ["laxative"], ["lesion"], ["lieutenant"], ["lion"], ["lip"], ["liver"],
   ["load"], ["lobotomy", "ies", -1], ["log"], ["longitude"], ["loser"], "lotion",
   ["lozenge"], ["lunchbox", "bits"], "malnutrition", ["manifold"], ["melon"],
   ["metronome"], ["minion"], ["miscreant"], ["mispronunciation"], "money",
   ["monkey"], ["mound"], ["mountain"], ["mouse", "mice"], ["neglect", "ers"],
   ["nostril", "doodads"], "nougat", "nutrition", "oblivion", ["obsession"],
   ["ointment"], ["omission"], ["onion"], ["opinion"], ["organ"],
   ["pageantry", "ies", -1], ["pajama"], ["pancake"], ["paradox", "es"],
   ["party", "ies", -1], "passion", ["pencil"], ["penny", "ies", -1], ["perplexer"],
   ["persecution", "persecuters"], "perspiration",
   ["persuasion", "persuaders"], ["perversion"], ["piano"], ["picnic"],
   ["pig"], ["pincushion"], ["piston"], ["pollution", "polluters"], ["pond"],
   "porno", ["potion"], ["prescription"], "preserves",
   ["pretense", "pretenders"], ["proclamation"], ["promotion"],
   ["pronunciation"], ["proportion"], ["proposition"],
   ["prosecution", "prosecutors"], ["prostitution", "prostitutes"],
   ["protein"], ["protrusion"], ["puppy", "ies", -1], "putty", ["rail"], "rain",
   ["raisin"], ["rebellion"], ["rectum"], ["redeemer"], ["reinforcement"],
   ["relaxation", "relaxers"], ["remainder"], ["removal", "removers"],
   "rendezvous", ["reservation"], ["retardation", "retarders"],
   ["retention", "retentives"], ["retraction", "rectractors"],
   ["retribution"], "revulsion", "rice", ["ring"], ["riot"], ["ripping-cat"],
   ["Ritz Cracker Crumb"],
   ["robber"], ["rodent"], ["rooster"], ["rotation", "rotators"],
   ["royalty", "ies", -1], "rubber", ["salad"], "salmon", ["sample"], "sand",
   ["sandwich", "es"], "sauce", ["scenario"], ["scorpion"], ["secretion"],
   ["seduction", "seducers"], ["selector"], ["shoe"], ["shrub", "bery"], ["ski"],
   ["sleeve"], ["snooze", "ers"], ["snore", "ignorers"], ["snowbulb"], ["sock"],
   "sodium", ["sofa"], "soft-serve", "soil", ["split"], ["squeeze", "checks"],
   ["squirrel"], ["stone"], "string-art", "suction", "sugar", ["suicide"],
   ["surprise"], ["suspension", "suspenders"], ["suspicion"], ["swindler"],
   ["sycophant"], ["table"], ["tampon"], "tape", ["televangelist"],
   ["television"], ["temptation"], ["tension"], "thunder", ["tool", "pliers"],
   ["toothpick"], ["translation", "translators"], "trash", "travesty",
   ["treaty", "ies", -1], "trout", ["trouser"], ["turkey"], ["unit"], ["vagrant"],
   "vapor", ["warrior"], ["watch", "watchers"], ["wavechord"], ["welt"], ["whip"],
   ["wig"], ["will-o'-the-wisp"], ["winch", "es"], ["wind"], "wine", ["winter"],
   ["witch", "es"], ["yarn"]
  );

sub shop_random {
  my $n = shift;

  return int rand $n;
}

sub shop_random_range {
  my $lower = shift;
  my $upper = shift if (@_ == 2);

  if (defined $upper) {
    return $lower + shop_random ($upper - $lower);
  } else {
    return shop_random $lower;
  }
}

sub shop_random_adjective {
  return $shop_adjectives[shop_random $#shop_adjectives];
}

sub shop_random_noun {

  my $entry = $shop_nouns[shop_random $#shop_nouns];

  if (ref $entry eq "ARRAY") {
    return $entry->[0];
  } else {
    return $entry;
  }
}

sub shop_random_plural {

  my $entry = $shop_nouns[shop_random $#shop_nouns];
  my $it;

  if (ref $entry ne "ARRAY") {
    return $entry;
  }

  if ($#{$entry} == 0) {
    return $entry->[0] . "s";
  }

  if ($#{$entry} == 1) {
    if (ref $entry->[1] ne "ARRAY") {
      return $entry->[1];
    } else {
      return $entry->[0] . $entry->[1];
    }
  }

  if ($#{$entry} == 2) {
    return substr($entry->[0], 0, $entry->[2]) . $entry->[1];
  }
}

sub shop_string {

  my $noun_1 = "";
  my $noun_2 = "";
  my $adj_1 = "";
  my $adj_2 = "";
  my $n = shop_random 5;

  $noun_1 = shop_random_noun if ($n >= 3);
  $noun_2 = shop_random_plural;
  while ($noun_2 eq $noun_1) {
    $noun_2 = shop_random_plural;
  }

  $n = shop_random 4;

  $adj_1 = shop_random_adjective if ($n == 3);
  $adj_2 = shop_random_adjective;
  while ($adj_2 eq $adj_1) {
    $adj_2 = shop_random_adjective;
  }

  $adj_1 .= " " if ($adj_1 ne "");
  $adj_2 .= " " if ($adj_2 ne "");
  $noun_1 .= " " if ($noun_1 ne "");

  return $adj_1 . $adj_2 . $noun_1 . $noun_2;
}

sub shop_string_list {
  my $n = shift if (@_ == 1);

  my @l;

  $n = 3 if (!defined $n);

  croak "argument must be positive: $n" if ($n < 0);

  while ($n > 0) {
    push @l, shop_string;
    $n--;
  }

  return @l;
}

sub shop_string_numbered_list {
  my $n = shift if (@_ == 1);

  my $i = 0;

  map { $i++; $_ = "($i) " . shop_capitalize_string $_; } shop_list_string $n;
}

sub shop_capitalize_string {
  my $str = shift;
  my $all = shift if (@_ == 2);

  if ($all) {
    $str = ucfirst $str;
    $str =~ s/\b(\S)\S+/uc $1/g;
    return $str;
  } else {
    return ucfirst $str;
  }
}

    
sub shop {
  my $prefix = shift if (@_ == 1);

  $prefix = 3 if (!defined $prefix);
  $prefix = -3 if (ref $prefix eq "ARRAY"); # ???

  my @l = shop_string_list abs $prefix;
  my $n = 1;
  my $countp = $prefix >= 0;

  print "Here is your shopping list:\n";

  while (@l) {
    if ($countp) {
      print "($n) " . shop_capitalize_string pop(@l) . "\n";
    } else {
      print pop(@l) . "\n";
    }
    $n++;
  }
}

sub shop_middle_name {

  print $ENV{USER} . ", your middle name is " . shop_capitalize_string shop_string, 1 . "\n";
}

if ($#ARGV == 0) {
  shop $ARGV[0];
} else {
  shop;
}
