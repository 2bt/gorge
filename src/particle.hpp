class Star : public Object {
public:
	Star() {
		init("media/star.png");
		speed = randFloat(0.3, 1);
		float c = (speed - 0.3) * 100;
		float d = c * randFloat(1, 2);
		setColor(sf::Color(c, d, d));
		reset();
		setPosition(randFloat(-10, 810), randFloat(-10, 610));
	}
	virtual bool update() {
		move(0, speed);
		if (getPosition().y > 632) reset();
		return true;
	}
	virtual void draw() {
		window.draw(*this, sf::BlendAdd);
	}
	float getSpeed() const { return speed; };
private:
	void reset() {
		setPosition(randFloat(-32, 832), -32);
		setFrame(randInt(0, 20) == 0);
	}
	float speed;
};


class Particle : public Object { };
extern std::forward_list<std::unique_ptr<Particle>> particles;



void triggerQuake();
class Explosion : public Particle {
public:
	Explosion(Vec2 pos) {
		init("media/explosion.png");
		setColor(sf::Color(255, 255, 100));
		setPosition(pos);
		triggerQuake();
		playSound("media/explosion.wav", pos).setPitch(randFloat(0.8, 1.3));
	}
	virtual bool update() {
		tick++;
		setFrame(tick);
		if (tick > frameCount) return false;
		return true;
	}
protected:
	Explosion() {};
	int tick = 0;
};


class Hit : public Explosion {
public:
	Hit(Vec2 pos) {
		init("media/hit.png");
		setColor(sf::Color(255, 255, 100));
		setPosition(pos);
		playSound("media/hit.wav", pos);
	}
};


template<typename T, typename... Args>
void makeParticle(Args&&... args) {
	particles.emplace_front(std::unique_ptr<Particle>(new T(args...)));
}

