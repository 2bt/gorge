#include <cstdio>
#include <memory>
#include <string>
#include <vector>
#include <forward_list>
#include <unordered_map>

#include <SFML/System.hpp>
#include <SFML/Window.hpp>
#include <SFML/Graphics.hpp>

#include "helper.hpp"

using namespace std;

void drawPoly(sf::RenderWindow& win, const Poly poly) {
	sf::VertexArray v(sf::Lines, 2);
	v[0].color = v[1].color = sf::Color::Red;
	for (size_t i = 0; i < poly.size(); i++) {
		v[0].position = poly[i];
		v[1].position = poly[(i + 1) % poly.size()];
		win.draw(v);
	}
}


float checkCollision(const Poly& a, const Poly& b, Vec2& normal, Vec2& where) {
	if (a.empty() || b.empty()) return 0;

	float distance = 9e99;
	for (size_t m = 0; m < 2; m++) {
		const Poly* pa = m ? &a : &b;
		const Poly* pb = m ? &b : &a;

		Vec2 p1 = (*pa)[pa->size() - 1];
		for (Vec2 p2: *pa) {
			float c_d = 0;
			Vec2 c_n;
			Vec2 c_w;
			Vec2 n = {p1.y - p2.y, p2.x - p1.x};
			for (Vec2 w: *pb) {
				float d = (p1.x - w.x) * n.x + (p1.y - w.y) * n.y;
				if (d > c_d) {
					c_d = d;
					c_n = n;
					c_w = w;
				}
			}
			if (c_d == 0) return 0;
			float ool = 1 / sqrtf(n.x * n.x + n.y * n.y);
			c_d *= ool;
			if (c_d < distance) {
				distance = c_d;
				if (m == 1) ool = -ool;
				normal = n * ool;
				where = c_w;
			}
			p1 = p2;
		}
	}
	return distance;
}


sf::Texture& loadTexture(const string& filename) {
	static unordered_map<string, sf::Texture> textures;

	if (!textures.count(filename)) {
		sf::Texture& tex = textures[filename];
		tex.loadFromFile(filename);
	}
	return textures[filename];
}



