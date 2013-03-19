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
#include "particle.hpp"
#include "player.hpp"
#include "badguy.hpp"


using namespace std;

Walls walls;
Player player;
std::forward_list<unique_ptr<Particle>> particles;
forward_list<unique_ptr<Laser>> lasers;
forward_list<unique_ptr<BadGuy>> badGuys;
forward_list<unique_ptr<Bullet>> bullets;



class RingGuy : public BadGuy {
public:
	RingGuy(Vec2 pos) : BadGuy(1) {
		init("media/ring.png");
		setPosition(pos);


		float ang = randFloat(0, M_PI);
		vel = Vec2(cos(ang), sin(ang)) * speed;

	}

	virtual bool update() {
		move(0, walls.getSpeed());
		move(vel);

		updateCollisionPoly();
		Vec2 normal;
		float distance = walls.checkCollision(poly, &normal);
		if (distance > 0) {
			move(normal * -distance);
			updateCollisionPoly();
			delay = 0;

			float ang = randFloat(0, 2 * M_PI);
			vel = Vec2(cos(ang), sin(ang)) * speed;
			if (dot(vel, normal) > 0) vel = -vel;
		}
		delay += randInt(1, 4);
		if (delay > 300) {
			delay = 0;
			float ang = randFloat(0, 2 * M_PI);
			vel = Vec2(cos(ang), sin(ang)) * speed;
		}

		setFrame(tick / 4);
		if (++tick >= frameCount * 4) tick = 0;

		Vec2 pos = getPosition();
		if (pos.x < -50 || pos.x > 850) return false;
		if (pos.y < -100 || pos.y > 650) return false;
		return checkCollisionWithLaser();
	}

private:
	const float speed = 2;
	int tick = 0;
	int delay;
	Vec2 vel;

	virtual const Poly& getCollisionModel() const {
		static const Poly model = {
			Vec2(2, 4),
			Vec2(4, 2),
			Vec2(4, -2),
			Vec2(2, -4),
			Vec2(-2, -4),
			Vec2(-4, -2),
			Vec2(-4, 2),
			Vec2(-2, 4),
		};
		return model;
	}
};


class RapidBullet : public Bullet {
public:
	RapidBullet(Vec2 pos, Vec2 velocity) {
		init("media/rapid.png");
		setPosition(pos);
		vel = velocity;
		rotate(atan2(vel.x, -vel.y + walls.getSpeed()) * 180 / M_PI);
	}
protected:
	virtual const Poly& getCollisionModel() const {
		static const Poly model = {
			Vec2(0.5, 2),
			Vec2(0.5, -2),
			Vec2(-0.5, -2),
			Vec2(-0.5, 2),
		};
		return model;
	}
};


class SquareGuy : public BadGuy {
public:
	SquareGuy(Vec2 pos) : BadGuy(2) {
		init("media/square.png");
		setPosition(pos);
		vel = normalized(Vec2(randFloat(-1, 1), 1)) * speed;
		tick = randInt(0, 150);
	}

	virtual bool update() {
		move(0, walls.getSpeed());
		move(vel);
		bounce = true;
		updateCollisionPoly();

		Vec2 normal;
		float distance = walls.checkCollision(poly, &normal);
		if (distance > 0) vel -= normal * 0.1f;
		else vel = normalized(vel) * speed;

		bounce = false;
		updateCollisionPoly();

		Vec2 pos = getPosition();

		if (tick > 155 || walls.look(pos, player.getPosition())) {
			tick = (tick + 1) % 180;
		}

		if (tick == 155 || tick == 163 || tick == 171) {
			Vec2 diff = player.getPosition() - pos;
			float ang = atan2(diff.x, diff.y) + randFloat(-0.1, 0.1);
			diff = Vec2(sin(ang), cos(ang));
			makeBullet<RapidBullet>(pos, diff * randFloat(4.5, 5));
		}

		setFrame(frame / 4);
		if (++frame >= frameCount * 4) frame = 0;

		if (pos.x < -50 || pos.x > 850) return false;
		if (pos.y < -100 || pos.y > 650) return false;
		return checkCollisionWithLaser();
	}

private:
	int frame = 0;
	int tick;
	Vec2 vel;
	bool bounce;
	const float speed = 1.2;

	virtual const Poly& getCollisionModel() const {
		static const Poly model = {
			Vec2(2, 4),
			Vec2(4, 2),
			Vec2(4, -2),
			Vec2(2, -4),
			Vec2(-2, -4),
			Vec2(-4, -2),
			Vec2(-4, 2),
			Vec2(-2, 4),
		};
		static const Poly bounceModel = {
			Vec2(3, 6),
			Vec2(6, 3),
			Vec2(6, -3),
			Vec2(3, -6),
			Vec2(-3, -6),
			Vec2(-6, -3),
			Vec2(-6, 3),
			Vec2(-3, 6),
		};
		return bounce ? bounceModel : model;
	}
};



class CannonGuy : public BadGuy {
public:
	CannonGuy(Vec2 pos, float ang) : BadGuy(1) {
		init("media/cannon.png");
		setPosition(pos);
		angle = ang;
		cannonAngle = ang + randFloat(-80, 80);
		setRotation(angle);
		tick = randInt(100, 200);
	}

	virtual bool update() {
		move(0, walls.getSpeed());
		updateCollisionPoly();

		Vec2 diff = player.getPosition() - getPosition();
		float ang = atan2(diff.x, -diff.y) * 180 / M_PI;

		float angDiff = fmodf(angle - ang + 540, 360) - 180;

		if (angDiff >= -100 && angDiff <= 100 && tick < 50 &&
			walls.look(getPosition(), player.getPosition())) {

			float speed = 1;
			float d = fmodf(cannonAngle - ang + 540, 360) - 180;
			if (d > speed) cannonAngle -= speed;
			else if (d < -speed) cannonAngle += speed;
			else {
				cannonAngle -= d;
				if (tick == 0) {
					tick = randInt(100, 150);
					diff = normalized(diff);
					makeBullet<Bullet>(getPosition() + diff * 16.0f, diff * 4.0f);
				}
			}
		}
		if (tick > 0) tick--;


		if (getPosition().y > 648) return false;
		return checkCollisionWithLaser();
	}

	virtual void draw(sf::RenderWindow& win) {
		setRotation(cannonAngle);
		setFrame(1);
		win.draw(*this);

		setRotation(angle);
		setFrame(0);
		win.draw(*this);
	}

private:
	float angle;
	float cannonAngle;
	int tick;


	virtual const Poly& getCollisionModel() const {
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




vector<Star> stars;


void update() {
	// spawn bad guys
	static int i = 0;

	i += randInt(1, 3);

	if (i > 300) {
		i = 0;

		Vec2 pos;
		float ang;
		if (walls.findFreeWallSpot(pos, ang)) {
			makeBadGuy<CannonGuy>(pos, ang);
		}


		if (walls.findFreeSpot(pos)) {
			makeBadGuy<SquareGuy>(pos);
		}

		if (walls.findFreeSpot(pos)) {
			makeBadGuy<RingGuy>(pos);
		}
	}



	for (auto& star: stars) star.update();
	walls.update();
	updateList(particles);
	updateList(lasers);
	updateList(bullets);
	player.update();
	updateList(badGuys);
}


void draw(sf::RenderWindow& win) {

	sf::View view = win.getDefaultView();
	view.zoom(2);
	view.move(0, -220);
//	win.setView(view);



	for (auto& star : stars) star.draw(win);
	for (auto& laser : lasers) laser->draw(win);
	for (auto& bullet : bullets) bullet->draw(win);
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

