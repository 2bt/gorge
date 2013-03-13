#include <cstdio>
#include <algorithm>
#include <memory>
#include <string>
#include <vector>
#include <array>
#include <forward_list>

#include <SFML/System.hpp>
#include <SFML/Window.hpp>
#include <SFML/Graphics.hpp>

#include "helper.hpp"
#include "object.hpp"

using namespace std;

static int randInt(int a, int b) { return a + rand() % (b - a + 1); }

static const vector<Poly> tileData = {
	{ },
	{ Vec2(0, 0), Vec2(0, 1), Vec2(1, 1), Vec2(1, 0) },
	{ Vec2(0, 0), Vec2(1, 1), Vec2(1, 0) },
	{ Vec2(0, 1), Vec2(1, 1), Vec2(1, 0) },
	{ Vec2(0, 0), Vec2(0, 1), Vec2(1, 1) },
	{ Vec2(0, 0), Vec2(0, 1), Vec2(1, 0) },
};

class Walls {
public:
	Walls() {

		tiles.resize(width * height, 1);
		for (int i = 0; i < 20; i++) generate();
	}

	void update() {
		offset += 0.03;
		if (offset >= 1) {
			offset -= 1;
			generate();
		}
	}

	void draw(sf::RenderWindow& win) {

		array<sf::Vertex, 4> v;

		for (int y = 0; y < 20; y++) {
			for (int x = 0; x < width; x++) {

				int t =  tiles[y * width + x];
				const Poly& p = tileData[t];


				for (size_t i = 0; i < p.size(); i++) {
					v[i].position = (p[i] + Vec2(x - 1, 18 - y + offset)) * 32.0f;
					v[i].color = sf::Color(100, 30, 60);
				}
				win.draw(v.data(), p.size(), sf::TrianglesFan);
			}
		}
	}

	float checkCollision(const Poly& poly, Vec2& normal, Vec2& where) {
		Poly v;

		float distance = 0;

		for (int y = 0; y < 20; y++) {
			for (int x = 0; x < width; x++) {

				int t =  tiles[y * width + x];
				const Poly& p = tileData[t];

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



private:
	const int width = 27;
	const int height = 50;
	vector<int> tiles;
	float offset = 0;

	float yy = 25;
	float xx = width * 0.5;;
	float r = width * 0.5;

	int getTile(int y, int x) const {
		return	y < 0 || y >= height ? 0 :
				x < 0 || x >= width ? 1 :
				tiles[y * width + x];
	}
	int& tileAt(int y, int x) {
		return tiles[y * width + x];
	}


	void generate() {

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

			float ang = (rand() / (float)RAND_MAX * 1.4 - 0.2) * M_PI;
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
};

Walls walls;




class Laser : public Object {
public:
	Laser(Vec2 pos) {
		init("media/laser.png");
		setPosition(pos);
	}
	virtual bool update() {
		move(vel);
		updateCollisionPoly();

		Vec2 normal, where;
		if (walls.checkCollision(poly, normal, where) > 0) {
			return false;
/*
			move(n * -d);
			n *= n.x * vel.x + n.y * vel.y;
			vel -= 2.0f * (vel - n);
			vel = - vel;
			rotate(-atan2(vel.x, vel.y) * 180 / M_PI);
*/
		}


		if (getPosition().y < -10) return false;
		return true;
	}
private:
	Vec2 vel = {0, -16};

	virtual const Poly& getCollisionModel() {
		static const Poly model = {
			Vec2(0.5, 2.5),
			Vec2(0.5, -2.5),
			Vec2(-0.5, -2.5),
			Vec2(-0.5, 2.5),
		};
		return model;
	}
};


forward_list<unique_ptr<Laser>> lasers;



class Player : public Object {
public:
	virtual void init() {
		Object::init("media/ship.png");
		setPosition(400, 500);
	}

	virtual bool update() {

		float joy_x = sf::Joystick::getAxisPosition(0, sf::Joystick::X);
		float joy_y = sf::Joystick::getAxisPosition(0, sf::Joystick::Y);
		Vec2 mov;
		mov.x = (sf::Keyboard::isKeyPressed(sf::Keyboard::Right) or joy_x > 50)
				-(sf::Keyboard::isKeyPressed(sf::Keyboard::Left) or joy_x < -50);
		mov.y = (sf::Keyboard::isKeyPressed(sf::Keyboard::Down) or joy_y > 50)
				-(sf::Keyboard::isKeyPressed(sf::Keyboard::Up) or joy_y < -50);
		Vec2 pos = getPosition();
		pos += mov * 3.0f;
		pos.x = min(pos.x, 784.0f);
		pos.x = max(pos.x, 16.0f);
		pos.y = min(pos.y, 584.0f);
		pos.y = max(pos.y, 16.0f);
		setPosition(pos);
		updateCollisionPoly();
		Vec2 normal, where;
		float distance = walls.checkCollision(poly, normal, where);
		if (distance > 0) {
			move(normal * -distance);
			pos = getPosition();
		}


		bool shoot =	sf::Joystick::isButtonPressed(0, 0) |
						sf::Keyboard::isKeyPressed(sf::Keyboard::X);

		if (shoot && !(tick % 10)) {
			lasers.push_front(unique_ptr<Laser>(new Laser(pos + Vec2(0, -10))));
		}

		setFrame(tick++ / 4 % 2);




		return true;
	}

/*
	virtual void draw(sf::RenderWindow& win) {
		drawPoly(win, poly);
		win.draw(*this);
	};
*/

private:
	virtual const Poly& getCollisionModel() {
		static const Poly model = {
			Vec2(4, 4),
			Vec2(4, 1),
			Vec2(1, -4),
			Vec2(-1, -4),
			Vec2(-4, 1),
			Vec2(-4, 4),
		};
		return model;
	}

	size_t tick = 0;
};


Player player;


void update() {
	walls.update();
	updateList(lasers);
	player.update();
}


void draw(sf::RenderWindow& win) {

	walls.draw(win);
	for (auto& laser: lasers) laser->draw(win);
	player.draw(win);
}


int main(int argc, char** argv) {

	sf::RenderWindow window(sf::VideoMode(800, 600), "sfml",
							sf::Style::Titlebar || sf::Style::Close);
	window.setFramerateLimit(60);
	window.setMouseCursorVisible(false);

	player.init();


	while (window.isOpen()) {
		sf::Event e;
		while (window.pollEvent(e)) {
			switch (e.type) {
			case sf::Event::Closed:
				window.close();
				break;

			case sf::Event::KeyPressed:
				if (e.key.code == sf::Keyboard::Escape) window.close();
				break;

			default:
				break;
			}

		}
		update();
		window.clear();
		draw(window);
		window.display();
	}

	return 0;
}

