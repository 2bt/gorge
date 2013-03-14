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

template<typename... Args>
void makeBullet(Args&&... args) {
	bullets.push_front(unique_ptr<Bullet>(new Bullet(args...)));
}


class CannonGuy : public BadGuy {
public:
	CannonGuy(Vec2 pos, float ang) : BadGuy(1) {
		init("media/cannon.png");
		setPosition(pos);
		angle = ang;
		cannonAngle = ang + randFloat(-90, 90);
		setRotation(angle);
	}


	int tick = 0;
	virtual bool update() {
		move(0, walls.getSpeed());

		if (walls.look(getPosition(), player.getPosition())) {
			Vec2 diff = player.getPosition() - getPosition();
			float a = atan2(diff.y, diff.x) * 180 / M_PI + 90;
			float d = fmodf(a - cannonAngle + 540, 360) - 180;
			if (d > 0) cannonAngle += 1;
			if (d < 0) cannonAngle -= 1;


			if (tick <= 0) {
				tick = 100;
				Vec2 dir = { sinf(cannonAngle * M_PI / 180), -cosf(cannonAngle * M_PI / 180)};
				makeBullet(getPosition(), dir * randFloat(3, 4));

			}
			else tick--;
		}
		else tick = 0;


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




vector<Star> stars;


void update() {
	for (auto& star: stars) star.update();
	updateList(particles);

	static int i = 0;
	if (!(i++ % 100)) {

		Vec2 pos;
		float ang;
		if (walls.findCannonGuyLocation(pos, ang)) {
			makeBadGuy<CannonGuy>(pos, ang);
		}

	}

	walls.update();
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

