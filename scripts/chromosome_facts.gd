# chromosome_facts.gd
# Text for the "Chromosome facts" panel: how Bio-Mites compare with real living things (haploid, polyploid,
# trisomy, crossing over). Written for grade 6 and up. Plain text only (shown in Labels).
class_name ChromosomeFacts
extends RefCounted

const TITLE: String = "Chromosome facts"

## [heading, body] pairs, shown in order
const SECTIONS: Array[Array] = [
	["Bio-Mites: exactly two of each",
		"A Bio-Mite has 3 kinds of chromosome and two copies of each kind, one from each parent: 6 in all. Scientists write this as 2n = 6, where n is the number of different chromosomes. In this game a Bio-Mite with any other number can't develop.\n\nThat rule is for Bio-Mites. Living things on Earth are more varied: some live with one copy of each chromosome, some with many, and some with one extra."],
	["Haploid: one copy of each",
		"Haploid cells have just one copy of each chromosome (n). Your egg or sperm cells are haploid; when they join, the new cell has two copies again.\n\nSome whole animals are haploid. Male honeybees (drones) hatch from eggs that were never fertilized, so they have one set of chromosomes, while the females (workers and queens) have two. Many wasps and ants work the same way. Mosses spend most of their lives haploid, and so do many fungi and algae."],
	["Polyploid: more than two sets",
		"Polyploid living things have three, four or even more full sets of chromosomes. This is common in plants. Bread wheat has six sets, garden strawberries have eight, potatoes have four, and the bananas sold in stores have three, which is why they have no real seeds. Seedless watermelons have three sets too. Flower growers breed plants such as daylilies to have four sets, which can give bigger, sturdier flowers.\n\nA few animals are polyploid as well, such as the gray treefrog of North America, which has four sets."],
	["Trisomy: one extra chromosome",
		"Trisomy means three copies of just one chromosome, while all the others have two. That is different from polyploidy: a whole extra set keeps the genes in balance, but one extra chromosome makes the cell use more of some genes than others.\n\nIn humans, most trisomies stop a pregnancy early. One that people live with is trisomy 21, or Down syndrome. People with Down syndrome go to school, work, make friends and live full lives, often with some extra support. Trisomy 18 and trisomy 13 are much more serious. Some people have an extra or missing sex chromosome, such as XXY (Klinefelter syndrome) or a single X (Turner syndrome), and live long lives.\n\nPlants show trisomy too. The jimsonweed plant has 12 kinds of chromosome, and scientists found a different trisomy for each one, each with its own seed-pod shape."],
	["Monosomy: one missing chromosome",
		"Monosomy means only one copy of a chromosome. In humans, missing one of the numbered chromosomes doesn't allow a baby to develop. Turner syndrome, with one X chromosome and no second sex chromosome, is the only monosomy people live with."],
	["Linked genes and crossing over",
		"Genes that sit on the same chromosome are linked: they usually travel together into the egg or sperm. That is why Level 5 can't be solved in this game.\n\nIn real living things, the link can break. When egg and sperm cells form, the two copies of a chromosome line up and can swap matching pieces. This is called crossing over. Two genes far apart on a chromosome are separated this way more often than two genes close together. This game doesn't model crossing over: its chromosomes always stay whole."],
]


## The whole panel as one plain-text string (used by tests and as a fallback)
static func full_text() -> String:
	var parts: Array[String] = []
	for section: Array in SECTIONS:
		parts.append(String(section[0]) + "\n" + String(section[1]))
	return "\n\n".join(parts)
