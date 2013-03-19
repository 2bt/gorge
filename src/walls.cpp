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

void Walls::init() {

	sf::Texture& tex = loadTexture("media/tiles.png");
	tileSprite.setTexture(tex);
	tileSprite.setScale(4, 4);
	tileSprite.setColor(sf::Color(60, 30, 70));

	offset = 0;
	flightLength = 0;
	tiles.resize(width * height, 1);
	circlePos = Vec2(width * 0.5, 24);
	radius = width * 0.5;
	for (int i = 0; i < 20; i++) generate();
}

void Walls::update() {
	offset += getSpeed();
	while (offset >= 32) {
		offset -= 32;
		flightLength++;
		generate();
	}
}

void Walls::draw(sf::RenderWindow& win) {
	for (int y = 0; y < 22; y++) {
//	for (int y = 0; y < height; y++) {

		for (int x = 0; x < width; x++) {
			int t =  tiles[y * width + x];
			tileSprite.setTextureRect(sf::IntRect(t * 8, 0, 8, 8));
			tileSprite.setPosition((x - 1) * 32, (19 - y) * 32 + offset);
			win.draw(tileSprite);

		}
	}
}



bool Walls::findFreeSpot(Vec2& pos) {

	vector<Vec2> locs;
	for (int x = 1; x < width - 1; x++) {
		Vec2 pos = Vec2((x - 0.5) * 32, (19.5 - 22) * 32 + offset);
		if (getTile(22, x) == 0 &&
			getTile(21, x - 1) == 0 &&
			getTile(21, x + 0) == 0 &&
			getTile(21, x + 1) == 0) {
			locs.push_back(pos);
		}
	}

	if (!locs.empty()) {
		pos = locs[randInt(0, locs.size() - 1)];
		return true;
	}
	return false;
}



bool Walls::findFreeWallSpot(Vec2& pos, float& ang) {
	struct Location { Vec2 pos; float ang; };
	vector<Location> locs;

	for (int x = 1; x < width - 1; x++) {
		Vec2 pos = Vec2((x - 0.5) * 32, (19.5 - 22) * 32 + offset);
		if (getTile(22, x) == 0) {

			const std::vector<int> nb = {
				getTile(22 + 1, x),
				getTile(22, x + 1),
				getTile(22 - 1, x),
				getTile(22, x - 1)
			};
			if (count(nb.begin(), nb.end(), 1) == 1 &&
				count(nb.begin(), nb.end(), 0) == 3) {
				float a = vector<float>{180, 270, 0, 90}
					[find(nb.begin(), nb.end(), 1) - nb.begin()];
				locs.push_back({ pos, a });
			}

		}
	}

	if (!locs.empty()) {
		Location& loc = locs[randInt(0, locs.size() - 1)];
		pos = loc.pos;
		ang = loc.ang;
		return true;
	}
	return false;
}


float Walls::checkCollision(const Poly& poly, Vec2* pnormal, Vec2* pwhere) {
	// very naive
	Vec2 normal;
	Vec2 where;
	Poly v;
	float distance = 0;
	for (int y = 0; y < 24; y++) {
		for (int x = 0; x < width; x++) {
			const Poly& p = tileData[tiles[y * width + x]];
			v.resize(p.size());
			for (size_t i = 0; i < p.size(); i++) {
				v[i].x = (p[i].x + x - 1) * 32;
				v[i].y = (p[i].y + 19 - y) * 32 + offset;
			}

			Vec2 n, w;
			float d = ::checkCollision(v, poly, &n, &w);
			if (d > distance) {
				distance = d;
				normal = n;
				where = w;
			}
		}
	}
	if (pnormal) *pnormal = normal;
	if (pwhere) *pwhere = where;
	return distance;
}



void Walls::generate() {

	copy(tiles.begin() + width, tiles.end(), tiles.begin());
	circlePos.y -= 1;

	while (circlePos.y < 40) {
		for (int y = 0; y < height; y++) {
			for (int x = 0; x < width; x++) {
				float dx = circlePos.x - x - 0.5;
				float dy = circlePos.y - y - 0.5;
				if (dx * dx + dy * dy < radius * radius) tileAt(y, x) = 0;
			}
		}

		float ang = randFloat(-0.2, 1.2) * M_PI;
		circlePos += Vec2(cos(ang), sin(ang)) * radius;
		circlePos.x = std::min(std::max(6.0f, circlePos.x), width - 6.0f);
		radius = randFloat(2, 7);
	}

	for (int x = 0; x < width; x++) {
		const std::vector<int> neighbors = {
			getTile(24 + 1, x) == 1,
			getTile(24, x + 1) == 1,
			getTile(24 - 1, x) == 1,
			getTile(24, x - 1) == 1
		};

		if (getTile(24, x) == 0) {
			if (count(neighbors.begin(), neighbors.end(), 1) == 3) tileAt(24, x) = 1;
			if (neighbors == std::vector<int>{ 1, 1, 0, 0 }) tileAt(24, x) = 2;
			if (neighbors == std::vector<int>{ 0, 1, 1, 0 }) tileAt(24, x) = 3;
			if (neighbors == std::vector<int>{ 0, 0, 1, 1 }) tileAt(24, x) = 4;
			if (neighbors == std::vector<int>{ 1, 0, 0, 1 }) tileAt(24, x) = 5;
		}
	}
}


