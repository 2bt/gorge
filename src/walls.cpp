#include <cstdio>
#include <algorithm>
#include <memory>
#include <string>
#include <vector>
#include <forward_list>

#include <SFML/System.hpp>
#include <SFML/Window.hpp>
#include <SFML/Graphics.hpp>

#include "helper.hpp"
#include "walls.hpp"

using namespace std;
static const vector<Poly> tileData = {
	{ },
	{ Vec2(0, 0), Vec2(0, 1), Vec2(1, 1), Vec2(1, 0) },
	{ Vec2(0, 0), Vec2(1, 1), Vec2(1, 0) },
	{ Vec2(0, 1), Vec2(1, 1), Vec2(1, 0) },
	{ Vec2(0, 0), Vec2(0, 1), Vec2(1, 1) },
	{ Vec2(0, 0), Vec2(0, 1), Vec2(1, 0) },
};

Walls::Walls() {

	sf::Texture& tex = loadTexture("media/tiles.png");
	tileSprite.setTexture(tex);
	tileSprite.setScale(4, 4);
	tileSprite.setColor(sf::Color(100, 30, 60));


	tiles.resize(width * height, 1);
	for (int i = 0; i < 20; i++) generate();
}

void Walls::update() {
	offset += 0.05;
	while (offset >= 1) {
		offset -= 1;
		generate();
	}
}

void Walls::draw(sf::RenderWindow& win) {
//	array<sf::Vertex, 4> v;
	for (int y = 0; y < 20; y++) {
		for (int x = 0; x < width; x++) {
			int t =  tiles[y * width + x];
/*			const Poly& p = tileData[t];
			for (size_t i = 0; i < p.size(); i++) {
				v[i].position = (p[i] + Vec2(x - 1, 18 - y + offset)) * 32.0f;
				v[i].color = sf::Color(100, 30, 60);
			}
			win.draw(v.data(), p.size(), sf::TrianglesFan);
*/			tileSprite.setTextureRect(sf::IntRect(t * 8, 0, 8, 8));
			tileSprite.setPosition(Vec2(x - 1, 18 - y + offset) * 32.0f);
			win.draw(tileSprite);

		}
	}
}

float Walls::checkCollision(const Poly& poly, Vec2& normal, Vec2& where) {
	Poly v;
	float distance = 0;
	for (int y = 0; y < 20; y++) {
		for (int x = 0; x < width; x++) {
			const Poly& p = tileData[tiles[y * width + x]];
			v.resize(p.size());
			for (size_t i = 0; i < p.size(); i++) {
				v[i] = (p[i] + Vec2(x - 1, 18 - y + offset)) * 32.0f;
			}

			Vec2 n, w;
			float d = ::checkCollision(v, poly, n, w);
			if (d > distance) {
				distance = d;
				normal = n;
				where = w;
			}
		}
	}
	return distance;
}



void Walls::generate() {

	copy(tiles.begin() + width, tiles.end(), tiles.begin());
	yy -= 1;

	while (yy < 40) {
		for (int y = 0; y < height; y++) {
			for (int x = 0; x < width; x++) {
				float dx = xx - x - 0.5;
				float dy = yy - y - 0.5;
				if (dx * dx + dy * dy < r * r) tileAt(y, x) = 0;
			}
		}

		float ang = randFloat(-0.2, 1.2) * M_PI;
		yy = yy + sin(ang) * r;
		xx = xx + cos(ang) * r;
		xx = std::min(std::max(6.0f, xx), width - 6.0f);
		r = randInt(20, 70) / 10;
	}

	for (int x = 0; x < width; x++) {
		const std::vector<int> neighbors = {
			getTile(25 + 1, x),
			getTile(25, x + 1),
			getTile(25 - 1, x),
			getTile(25, x - 1)
		};

		if (getTile(25, x) == 0) {
			if (std::count(neighbors.begin(), neighbors.end(), 1) == 3) tileAt(25, x) = 1;
			if (neighbors == std::vector<int>{ 1, 1, 0, 0 }) tileAt(25, x) = 2;
			if (neighbors == std::vector<int>{ 0, 1, 1, 0 }) tileAt(25, x) = 3;
			if (neighbors == std::vector<int>{ 0, 0, 1, 1 }) tileAt(25, x) = 4;
			if (neighbors == std::vector<int>{ 1, 0, 0, 1 }) tileAt(25, x) = 5;
		}
	}
}


