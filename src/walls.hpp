class Walls {
public:
	void init();
	void update();
	void draw(sf::RenderWindow& win);
	float checkCollision(const Poly& poly, Vec2& normal, Vec2& where);
	float getSpeed() {
		return 1.5;
	}

	int getTile(int y, int x) const {
		return	y < 0 || y >= height ? 0 :
				x < 0 || x >= width ? 1 :
				tiles[y * width + x];
	}
	int& tileAt(int y, int x) {
		return tiles[y * width + x];
	}

	const int width = 27;
	const int height = 50;

	float offset;
private:
	sf::Sprite tileSprite;
	std::vector<int> tiles;

	int	flightLength;

	Vec2 circlePos;
	float radius;

	void generate();
};


