shader_type canvas_item;

// Supprime les pixels de fond (blanc, gris, damier, fond légèrement teinté)
// Les vaisseaux sont bleu/violet/cyan → saturation haute.
// Les fonds et damiers ont saturation basse quelle que soit leur teinte.

void fragment() {
	vec4 col = texture(TEXTURE, UV);

	// Supprime les pixels complètement transparents
	if (col.a < 0.1) {
		discard;
	}

	float maxC = max(col.r, max(col.g, col.b));
	float minC = min(col.r, min(col.g, col.b));
	float saturation = maxC - minC;

	// Supprime tout pixel quasi-neutre (fond blanc, gris, damier)
	// Fond blanc/damier : chroma ≈ 0.0–0.05
	// Cockpit clair, métal : chroma ≈ 0.12–0.25 → préservés
	// Contours noirs : maxC < 0.15 → préservés
	if (saturation < 0.12 && maxC > 0.15) {
		discard;
	}

	COLOR = col;
}
