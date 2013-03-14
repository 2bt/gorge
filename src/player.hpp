

class Laser : public Object {
public:
	Laser(Vec2 pos);
	virtual bool update();
	void die() { alive = false; }
private:
	Vec2 vel;
	bool alive = true;
	virtual const Poly& getCollisionModel();
};


extern std::forward_list<std::unique_ptr<Laser>> lasers;




class Player : public Object {
public:
	virtual void init();
	virtual bool update();

private:
	bool checkCollisionWithBullets();
	virtual const Poly& getCollisionModel();

	int tick = 0;
	int shootDelay;
	int score;
};

extern Player player;
