#include <cstdio>
#include <memory>
#include <string>
#include <vector>
#include <forward_list>
#include <unordered_map>

#include "helper.hpp"


using namespace std;

void drawPoly(const Poly poly) {
	sf::VertexArray v(sf::Lines, 2);
	v[0].color = v[1].color = sf::Color::Red;
	for (size_t i = 0; i < poly.size(); i++) {
		v[0].position = poly[i];
		v[1].position = poly[(i + 1) % poly.size()];
		window.draw(v);
	}
}


bool checkLineIntersection(Vec2 a1, Vec2 a2, Vec2 b1, Vec2 b2, float& ai, float& bi) {

	Vec2 da = a2 - a1;
	Vec2 db = b2 - b1;
	Vec2 ab = b1 - a1;

	float det = cross(da, db);
	if (abs(det) < 0.0001) return false; // parallel


	ai = cross(ab, db) / det;
	bi = cross(ab, da) / det;

	if (ai < 0 || ai > 1) return false;
	if (bi < 0 || bi > 1) return false;
	return true;
}



float checkCollision(const Poly& a, const Poly& b, Vec2* pnormal, Vec2* pwhere) {
	Vec2 normal;
	Vec2 where;
	if (a.empty() || b.empty()) return 0;

	float distance = 9e99;
	for (size_t m = 0; m < 2; m++) {
		const Poly* pa = m ? &a : &b;
		const Poly* pb = m ? &b : &a;

		Vec2 p1 = pa->back();
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
	if (pnormal) *pnormal = normal;
	if (pwhere) *pwhere = where;
	return distance;
}

/*
sf::Texture& loadTexture(const string& filename) {
	static unordered_map<string, sf::Texture> textures;

	if (!textures.count(filename)) {
		sf::Texture& tex = textures[filename];
		tex.loadFromFile(filename);
	}
	return textures[filename];
}
*/


template<class T>
T& loadResource(const string& filename) {
	static unordered_map<string, T> resources;
	if (!resources.count(filename)) {
		T& t = resources[filename];
		t.loadFromFile(filename);
	}
	return resources[filename];
}


sf::Texture& loadTexture(const string& filename) {
	return loadResource<sf::Texture>(filename);
}



static sf::SoundBuffer& loadSoundBuffer(const string& filename) {
	return loadResource<sf::SoundBuffer>(filename);
}

static forward_list<sf::Sound> sounds;


sf::Sound& playSound(const string& filename, Vec2 pos) {
	sounds.emplace_front(loadSoundBuffer(filename));
	sf::Sound& sound = sounds.front();
	sound.setPosition(pos.x, pos.y, 0);
	sound.setAttenuation(0.005);
	sound.play();

	return sound;
}


void updateSounds() {
	auto prevIt = sounds.before_begin();
	for (auto it = sounds.begin(); it != sounds.end(); it++) {
		if (it->getStatus() == sf::Sound::Stopped) {
			sounds.erase_after(prevIt);
			it = prevIt;
		}
		else prevIt = it;
	}
}


