class Laser : public Object {
public:
	Laser(Vec2 pos);
	virtual bool update();
	void die() { alive = false; }
	int getDamage() { return 1; }
private:
	Vec2 vel;
	bool alive;
	virtual const Poly& getCollisionModel() const;
};


extern std::forward_list<std::unique_ptr<Laser>> lasers;




class Player : public Object {
public:
	virtual void init();
	virtual bool update();

	void raiseScore(int x) { score += x; }
	int getScore() { return score; }

private:
	bool checkCollisionWithBullets();
	bool checkCollisionWithBadGuys();
	virtual const Poly& getCollisionModel() const;
	void takeHit();

	int tick;
	int shootDelay;
	int score;
};

extern Player player;
