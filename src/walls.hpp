
class Walls {
public:
	void init();
	void update();
	void draw(sf::RenderWindow& win);
	float checkCollision(const Poly& poly, Vec2* pnormal=nullptr, Vec2* pwhere=nullptr);
	bool findCannonGuyLocation(Vec2& pos, float& ang);


	bool look(Vec2 src, Vec2 dst) {
		// naive and bad
		Poly line = { src, dst };
		return checkCollision(line) == 0;
	}

	int getTile(int y, int x) const {
		return	y < 0 || y >= height ? 0 :
				x < 0 || x >= width ? 1 :
				tiles[y * width + x];
	}
	int& tileAt(int y, int x) {
		return tiles[y * width + x];
	}
	float getSpeed() const {
		return 1.25;
	}


	const int width = 27;
	const int height = 50;

private:
	sf::Sprite tileSprite;
	std::vector<int> tiles;
	float offset;
	int	flightLength;

	Vec2 circlePos;
	float radius;

	void generate();
};


extern Walls walls;
