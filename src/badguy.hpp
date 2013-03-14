class Bullet : public Object {
public:
	Bullet(Vec2 pos, Vec2 velocity) {
		init("media/bullet.png");
		setPosition(pos);
		vel = velocity;
	}

	virtual bool update() {
		move(vel);
		updateCollisionPoly();
		Vec2 pos = getPosition();
		if (walls.checkCollision(poly) > 0) {
			makeParticle<Hit>(pos);
			return false;
		}
		if (pos.x < -40 || pos.x > 840) return false;
		if (pos.y < -40 || pos.y > 640) return false;

		return alive;
	}

	void die() { alive = false; }

protected:
	Vec2 vel;
	bool alive = true;

	virtual const Poly& getCollisionModel() {
		static const Poly model = {
			Vec2(1, 1),
			Vec2(1, -1),
			Vec2(-1, -1),
			Vec2(-1, 1),
		};
		return model;
	}
};


extern std::forward_list<std::unique_ptr<Bullet>> bullets;



class BadGuy : public Object {
public:


	BadGuy(int shield) : shield(shield) {}
protected:
	bool checkCollisionWithLaser() {
		for (auto& laser : lasers) {
			if (::checkCollision(poly, laser->getCollisionPoly()) > 0) {
				makeParticle<Hit>(laser->getPosition());
				laser->die();
				shield--;
				if (shield <= 0) {
					makeParticle<Explosion>(getPosition());
					break;
				}
			}
		}
		return shield > 0;
	}
private:
	int shield;
};

extern std::forward_list<std::unique_ptr<BadGuy>> badGuys;


template<typename T, typename... Args>
void makeBadGuy(Args&&... args) {
	badGuys.push_front(std::unique_ptr<BadGuy>(new T(args...)));
}
