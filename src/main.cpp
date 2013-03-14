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
#include "object.hpp"
#include "walls.hpp"


using namespace std;

class Particle : public Object { };
forward_list<unique_ptr<Particle>> particles;



class Explosion : public Particle {
public:
	Explosion(Vec2 pos) {
		init("media/explosion.png");
		setColor(sf::Color(255, 255, 100));
		setPosition(pos);
//		setRotation(randFloat(0, 360));
	}
	virtual bool update() {
		tick++;
		setFrame(tick);
		if (tick > frameCount) return false;
		return true;
	}
	virtual void draw(sf::RenderWindow& win) {
		win.draw(*this, sf::BlendAdd);
	}
protected:
	Explosion() {};
	size_t tick = 0;
};
class Hit : public Explosion {
public:
	Hit(Vec2 pos) {
		init("media/hit.png");
		setColor(sf::Color(255, 255, 100));
		setPosition(pos);
		setRotation(randFloat(0, 360));
	}
};
void makeExplosion(Vec2 pos) {
	particles.push_front(unique_ptr<Particle>(new Explosion(pos)));
}
void makeHit(Vec2 pos) {
	particles.push_front(unique_ptr<Particle>(new Hit(pos)));
}



class Star : public Object {
public:
	Star() {
		init("media/star.png");
		speed = randFloat(0.3, 1);
		float c = (speed - 0.3) * 100;
		float d = c * randFloat(1,2);
		setColor(sf::Color(c, d, d));
		reSet();
		setPosition(randFloat(-10, 810), randFloat(-10, 610));
	}
	virtual bool update() {
		move({0, speed});
		if (getPosition().y > 632) reSet();
		return true;
	}
	virtual void draw(sf::RenderWindow& win) {
		win.draw(*this, sf::BlendAdd);
	}
	float getSpeed() const { return speed; };
private:
	void reSet() {
		setPosition(randFloat(-32, 832), -32);
		setFrame(randInt(0, 20) == 0);
	}
	float speed;
};


Walls walls;


class Laser : public Object {
public:
	Laser(Vec2 pos) {
		init("media/laser.png");
		setPosition(pos);
		vel = {0, -16};
		alive = true;
	}
	virtual bool update() {
		move(vel);
		updateCollisionPoly();

		float distance = walls.checkCollision(poly);
		if (distance > 0) {
			makeHit(getPosition());
			return false;
		}

		if (getPosition().y < -16) return false;
		return alive;
	}
	void die() {
		alive = false;
	}
private:
	Vec2 vel;
	bool alive;

	virtual const Poly& getCollisionModel() {
		static const Poly model = {
			Vec2(1, 3),
			Vec2(1, -3),
			Vec2(-1, -3),
			Vec2(-1, 3),
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
		mov.x = (sf::Keyboard::isKeyPressed(sf::Keyboard::Right) or joy_x > 50) -
				(sf::Keyboard::isKeyPressed(sf::Keyboard::Left) or joy_x < -50);
		mov.y = (sf::Keyboard::isKeyPressed(sf::Keyboard::Down) or joy_y > 50) -
				(sf::Keyboard::isKeyPressed(sf::Keyboard::Up) or joy_y < -50);
		Vec2 pos = getPosition();
		pos += mov * 3.0f;
		pos.x = min(pos.x, 784.0f);
		pos.x = max(pos.x, 16.0f);
		pos.y = min(pos.y, 584.0f);
		pos.y = max(pos.y, 16.0f);
		setPosition(pos);
		updateCollisionPoly();
		Vec2 normal;
		float distance = walls.checkCollision(poly, &normal);
		if (distance > 0) {
			// TODO: explode here
			move(normal * -distance);
			pos = getPosition();
		}


		bool shoot =	sf::Joystick::isButtonPressed(0, 0) |
						sf::Keyboard::isKeyPressed(sf::Keyboard::X);

		if (shoot) {
			if (shootDelay == 0) {
				lasers.push_front(unique_ptr<Laser>(new Laser(pos + Vec2(0, -10))));
				shootDelay = 15;
			}
			else shootDelay--;
		}
		else shootDelay = 0;


		setFrame(tick++ / 4 % 2);

		return true;
	}


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

	size_t shootDelay;
	size_t tick = 0;
};

Player player;


class BadGuy : public Object {
public:
	BadGuy(int shield) : shield(shield) {}
protected:
	bool checkCollisionWithLaser() {
		for (auto& laser : lasers) {
			if (::checkCollision(poly, laser->getCollisionPoly()) > 0) {
				makeHit(laser->getPosition());
				laser->die();
				shield--;
				if (shield <= 0) {
					makeExplosion(getPosition());
					break;
				}
			}
		}
		return shield > 0;
	}
private:
	int shield;
};


class CannonGuy : public BadGuy {
public:
	CannonGuy(Vec2 pos, float ang) : BadGuy(1) {
		init("media/cannon.png");
		setPosition(pos);
		angle = ang;
		cannonAngle = ang + randFloat(-90, 90);
		setRotation(angle);

	}
	virtual bool update() {
		move(0, walls.getSpeed());

		if (walls.look(getPosition(), player.getPosition())) {
			Vec2 diff = player.getPosition() - getPosition();
			float a = atan2(diff.y, diff.x) * 180 / M_PI + 90;
			float d = fmodf(a - cannonAngle + 540, 360) - 180;
			if (d > 0) cannonAngle += 1;
			if (d < 0) cannonAngle -= 1;
		}

		if (getPosition().y > 648) return false;
		updateCollisionPoly();
		return checkCollisionWithLaser();
	}

	virtual void draw(sf::RenderWindow& win) {
		setRotation(cannonAngle);
		setFrame(1);
		win.draw(*this);

		setRotation(angle);
		setFrame(0);
		win.draw(*this);

//		drawPoly(win, poly);
	}

private:
	float angle;
	float cannonAngle;


	virtual const Poly& getCollisionModel() {
		static const Poly model = {
			Vec2(4, 4),
			Vec2(4, 0),
			Vec2(2, -4),
			Vec2(-2, -4),
			Vec2(-4, 0),
			Vec2(-4, 4),
		};
		return model;
	}
};






forward_list<unique_ptr<BadGuy>> badGuys;
vector<Star> stars;


void update() {
	for (auto& star: stars) star.update();
	updateList(particles);

	static int i = 0;
	if (!(i++ % 100)) {

		Vec2 pos;
		float ang;
		if (walls.findCannonGuyLocation(pos, ang)) {
			badGuys.push_front(unique_ptr<BadGuy>(new CannonGuy(pos, ang)));
		}

	}

	walls.update();
	updateList(lasers);
	player.update();

	updateList(badGuys);
}


void draw(sf::RenderWindow& win) {
/*
	sf::View view = win.getDefaultView();
	view.zoom(2);
	view.move(0, -200);
	win.setView(view);
*/


	for (auto& star : stars) star.draw(win);
	for (auto& laser : lasers) laser->draw(win);
	for (auto& guy : badGuys) guy->draw(win);
	player.draw(win);

	walls.draw(win);

	for (auto& particle : particles) particle->draw(win);





	drawPoly(win, {{-1,-1}, {801, -1}, {801, 601}, {-1, 601}});
}


int main(int argc, char** argv) {
	srand((unsigned)time(nullptr));

	sf::RenderWindow window(sf::VideoMode(800, 600), "sfml",
							sf::Style::Titlebar || sf::Style::Close);
	window.setFramerateLimit(60);
	window.setMouseCursorVisible(false);
	walls.init();
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

