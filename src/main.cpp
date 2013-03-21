#include <cstdio>
#include <stdarg.h>
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

sf::RenderWindow window;

class : public sf::Sprite {
public:
	void init() {
		sf::Texture& tex = loadTexture("media/font.png");
		setTexture(tex);
		setScale(2, 2);
	}

	void print(Vec2 pos, const char* text, ...) {

		char line[256];
		va_list args;
		va_start(args, text);
		vsnprintf(line, 256, text, args);
		va_end(args);

		setPosition(pos);
		for (char c : line) {
			if (c <= 0) break;

			setTextureRect(sf::IntRect(c % 8 * 8, c / 8 * 8, 8, 8));
			window.draw(*this);
			move(16, 0);
		}

	}
} font;



Walls walls;
Player player;
std::forward_list<unique_ptr<Particle>> particles;
forward_list<unique_ptr<Laser>> lasers;
forward_list<unique_ptr<BadGuy>> badGuys;
forward_list<unique_ptr<Bullet>> bullets;


class QueueGuy : public BadGuy {
public:
	QueueGuy(Vec2 pos) : BadGuy(1, 70) {
		init("media/queue.png");
		setPosition(pos);

		vel = Vec2(randFloat(-1, 1), 1);

		tick = randInt(0, 200);
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
			// bounce of walls
			vel -= 2.0f * normal * dot(vel, normal);
		}

		Vec2 pos = getPosition();

		// find leader
		QueueGuy* leader = nullptr;
		float squareDist = 10000;
		for (unique_ptr<BadGuy>& guy : badGuys) {
			QueueGuy* queue = dynamic_cast<QueueGuy*>(&*guy);
			if (queue && queue != this) {
				Vec2 diff = queue->getPosition() - pos;
				Vec2 dir = normalized(diff);
				if (dot(normalized(vel), dir) > 0.1 && dot(vel, queue->vel) > 0.1) {
					float d = dot(diff, diff);
					if (d < squareDist) {
						squareDist = d;
						leader = queue;
					}
				}
			}
		}



		if (leader) { // follow
			Vec2 dst = leader->getPosition() - normalized(leader->vel) * 50.0f;
			Vec2 dir = dst - pos;
			Vec2 a = dir * 0.01f + (leader->vel - vel) * 0.2f;
			if (length(a) > 0.1f) a *= 0.1f / length(a);
			vel += a;


			// shoot
			tick += randInt(1, 2);
			if (tick >= 300 && !walls.shootAt(getPosition(), player.getPosition())) {
				tick = randInt(0, 100);
				Vec2 dir = normalized(player.getPosition() - getPosition());
				makeBullet<Bullet>(getPosition(), dir * randFloat(3.7, 4));
			}

		}
		else { // lead

			Vec2 dir = normalized(vel);
			Vec2 perp(dir.y, -dir.x);


			if (--turnDelay <= 0) {
				turn = randFloat(-1, 1) * 0.03;
				turnDelay = randInt(30, 100);
			}

			float dodge = turn;
			float i1, i2;
			bool s1 = walls.shootAt(pos + perp * 10.0f, pos + dir * 60.0f + perp * 40.0f, &i1);
			bool s2 = walls.shootAt(pos - perp * 10.0f, pos + dir * 60.0f - perp * 40.0f, &i2);
			if (s1 || s2) {
				dodge = (s1 < s2 || i1 < i2) ? -0.2 * (1 - i2) : 0.2 * (1 - i1);
				vel *= 0.98f;
			}


			float ss = sin(dodge);
			float cc = cos(dodge);
			vel = Vec2(
				vel.x * cc - vel.y * ss,
				vel.x * ss + vel.y * cc
			);

			float v = length(vel);
			if (v < 2.2) vel += dir * 0.05f;


		}
		float v = length(vel);
		if (v > 2.8) vel *= 2.8f / v;

		setRotation(atan2(-vel.x, vel.y) * 180 / M_PI);




		setFrame(frame / 4);
		if (++frame >= frameCount * 4) frame = 0;

		if (pos.x < -50 || pos.x > 850) return false;
		if (pos.y < -200 || pos.y > 650) return false;
		return checkCollisionWithLaser();
	}

private:
	const float speed = 2;
	int frame = 0;

	float turn = 0;
	int turnDelay = 0;
	int tick;
	Vec2 vel;

	virtual const Poly& getCollisionModel() const {
		static const Poly model = {
			Vec2(3, 4),
			Vec2(3, -4),
			Vec2(-3, -4),
			Vec2(-3, 4),
		};
		return model;
	}
};



class RingGuy : public BadGuy {
public:
	RingGuy(Vec2 pos) : BadGuy(1, 100) {
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
	SquareGuy(Vec2 pos) : BadGuy(2, 250) {
		init("media/square.png");
		setPosition(pos);
		vel = normalized(Vec2(randFloat(-1, 1), 1)) * speed;
		tick = randInt(0, 100);
	}

	virtual bool update() {
		move(0, walls.getSpeed());
		move(vel);
		bounce = true;
		updateCollisionPoly();

		Vec2 normal;
		float distance = walls.checkCollision(poly, &normal);
		if (distance > 0) vel -= normal * 0.06f;
		else vel = normalized(vel) * speed;

		bounce = false;
		updateCollisionPoly();

		Vec2 pos = getPosition();

		if (tick >= 170 || !walls.shootAt(pos, player.getPosition())) tick++;
		if (tick == 170 || tick == 180 || tick == 190) {
			Vec2 diff = player.getPosition() - pos;
			float ang = atan2(diff.x, diff.y) + randFloat(-0.1, 0.1);
			diff = Vec2(sin(ang), cos(ang));
			makeBullet<RapidBullet>(pos, diff * randFloat(4.2, 4.6));
			if (tick == 190) tick = 0;
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
	const float speed = 1.1;

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
	CannonGuy(Vec2 pos, float ang) : BadGuy(1, 200) {
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
			!walls.shootAt(getPosition(), player.getPosition())) {

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

	virtual void draw() {
		setRotation(cannonAngle);
		setFrame(1);
		window.draw(*this);

		setRotation(angle);
		setFrame(0);
		window.draw(*this);
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

	// spawn bad guys here
	Vec2 pos;
	float ang;

	static int i = 0;
	i++;;
	i %= 400;

	if (i == 0) {

		if (walls.findFreeWallSpot(pos, ang)) makeBadGuy<CannonGuy>(pos, ang);
		if (walls.findFreeSpot(pos)) makeBadGuy<RingGuy>(pos);

	}
	if (i == 50) {
		if (walls.findFreeSpot(pos)) makeBadGuy<SquareGuy>(pos);
		if (walls.findFreeSpot(pos)) makeBadGuy<QueueGuy>(pos);
		if (walls.findFreeSpot(pos)) makeBadGuy<QueueGuy>(pos);
	}
	if (i == 100) {
		if (walls.findFreeSpot(pos)) makeBadGuy<RingGuy>(pos);
		if (walls.findFreeSpot(pos)) makeBadGuy<RingGuy>(pos);
	}

	if (i == 300) {

		if (walls.findFreeSpot(pos)) {
			makeBadGuy<QueueGuy>(pos);
			makeBadGuy<QueueGuy>(pos - Vec2(0, 50));
			makeBadGuy<QueueGuy>(pos - Vec2(0, 100));
		}
		if (walls.findFreeSpot(pos)) makeBadGuy<QueueGuy>(pos);
	}





	for (auto& star: stars) star.update();
	walls.update();
	updateList(particles);
	updateList(lasers);
	updateList(bullets);
	player.update();
	updateList(badGuys);
}



float quakeAmp = 0;
void triggerQuake() {
	quakeAmp += 5;
	quakeAmp = min(quakeAmp, 10.0f);
}


void draw() {
/*
	sf::View view = win.getDefaultView();
	view.zoom(2);
	view.move(0, -220);
	window.setView(view);
*/

	window.setView(window.getDefaultView());

	for (auto& star : stars) star.draw();

/*
	quakeAmp *= 0.93;
	float ang = randFloat(0, 2 * M_PI);
	sf::View view = window.getDefaultView();
	view.move(int(sin(ang) * quakeAmp), int(cos(ang) * quakeAmp));
	window.setView(view);
*/

	for (auto& laser : lasers) laser->draw();
	for (auto& bullet : bullets) bullet->draw();
	for (auto& guy : badGuys) guy->draw();
	player.draw();
	walls.draw();
	for (auto& particle : particles) particle->draw();


	window.setView(window.getDefaultView());

	font.setColor(sf::Color(255, 255, 255, 200));
	font.print(Vec2(10, 10), "PLAYER 1");
	font.print(Vec2(790 - 8 * 16, 10), "%8d", player.getScore());


//	drawPoly(window, {{-1,-1}, {801, -1}, {801, 601}, {-1, 601}});
}


int main(int argc, char** argv) {
	srand((unsigned)time(nullptr));

	window.create(sf::VideoMode(800, 600), "sfml",
							sf::Style::Titlebar || sf::Style::Close);
	window.setFramerateLimit(60);
	window.setMouseCursorVisible(false);
	font.init();


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

		window.clear();

		update();

		draw();

		window.display();
	}
	return 0;
}

