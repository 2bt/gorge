extern sf::RenderWindow window;

using Vec2 = sf::Vector2f;
using Poly = std::vector<Vec2>;


inline float dot(Vec2 a, Vec2 b) { return a.x * b.x + a.y * b.y; }
inline float cross(Vec2 a, Vec2 b) { return a.x * b.y - a.y * b.x; }
inline float length(Vec2 v) { return sqrt(dot(v, v)); }
inline Vec2 normalized(Vec2 v) { return v / length(v); }

inline int randInt(int min, int max) {
	return min + rand() % (max - min + 1);
}

inline float randFloat(float min, float max) {
	return min + rand() / (float)RAND_MAX * (max - min);
}

void drawPoly(const Poly poly);

bool checkLineIntersection(Vec2 a1, Vec2 a2, Vec2 b1, Vec2 b2, float& ai, float& bi);

float checkCollision(const Poly& a, const Poly& b,
		Vec2* pnormal=nullptr, Vec2* pwhere=nullptr);

template<class T>
void updateList(std::forward_list<std::unique_ptr<T>>& list) {
	auto prevIt = list.before_begin();
	for (auto it = list.begin(); it != list.end(); it++) {
		if (!(*it)->update()) {
			list.erase_after(prevIt);
			it = prevIt;
		}
		else prevIt = it;
	}
}

sf::Texture& loadTexture(const std::string& filename);

