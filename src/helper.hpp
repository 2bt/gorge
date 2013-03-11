using Vec2 = sf::Vector2f;
using Poly = std::vector<Vec2>;


void drawPoly(sf::RenderWindow& win, const Poly poly);
float checkCollision(const Poly& a, const Poly& b, Vec2& normal, Vec2& where);

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


