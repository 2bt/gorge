class Walls {
public:
	Walls();
	void update();
	void draw(sf::RenderWindow& win);
	float checkCollision(const Poly& poly, Vec2& normal, Vec2& where);


private:
	sf::Sprite tileSprite;
	const int width = 27;
	const int height = 50;
	std::vector<int> tiles;
	float offset = 0;

	float yy = 25;
	float xx = width * 0.5;;
	float r = width * 0.5;

	int getTile(int y, int x) const {
		return	y < 0 || y >= height ? 0 :
				x < 0 || x >= width ? 1 :
				tiles[y * width + x];
	}
	int& tileAt(int y, int x) {
		return tiles[y * width + x];
	}

	void generate();
};


