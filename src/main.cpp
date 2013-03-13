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
#include "walls.hpp"

using namespace std;


Walls walls;



class Star : public Object {
public:
	Star() {
		init("media/star.png");
		speed = randFloat(0.3, 1);
		float c = (speed - 0.3) * 100;
		setColor(sf::Color(c, c, c * 1.2));
		reSet();
		setPosition({randFloat(-10, 810), randFloat(-10, 610)});
	}
	virtual bool update() {
		move({0, speed});
		if (getPosition().y > 610) reSet();
		return true;
	}
	float getSpeed() const { return speed; };
private:
	void reSet() {
		setPosition({randFloat(-10, 810), -10});
		setFrame(randInt(0, 20) == 0);
	}
	float speed;;
};



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
		float distance = walls.checkCollision(poly, normal, where);
		if (distance > 0) return false;

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
vector<Star> stars;


void update() {
	for (auto& star: stars) star.update();

	walls.update();
	updateList(lasers);
	player.update();
}


void draw(sf::RenderWindow& win) {

	for (auto& star: stars) star.draw(win);

	walls.draw(win);
	for (auto& laser: lasers) laser->draw(win);
	player.draw(win);
}


int main(int argc, char** argv) {
	srand((unsigned)time(0));

	sf::RenderWindow window(sf::VideoMode(800, 600), "sfml",
							sf::Style::Titlebar || sf::Style::Close);
	window.setFramerateLimit(60);
	window.setMouseCursorVisible(false);

	player.init();

	stars.resize(100);
	sort(stars.begin(), stars.end(), [](const Star& a, const Star& b) {
		return a.getSpeed() < b.getSpeed();
	});


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

