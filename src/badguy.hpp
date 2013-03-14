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

extern std::forward_list<std::unique_ptr<BadGuy>> badGuys;

