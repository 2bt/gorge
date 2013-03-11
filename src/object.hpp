
class Object : public sf::Sprite {
public:
	Object() {};
	virtual ~Object() {};
	virtual void init(const std::string& filename) {
		sf::Texture& tex = loadTexture(filename);
		auto s = tex.getSize();
		spriteWidth = s.y;
		frameCount = s.x / spriteWidth;
		setTexture(tex);
		setOrigin(spriteWidth * 0.5, spriteWidth * 0.5);
		setScale(4, 4);
		setTextureRect(sf::IntRect(0, 0, s.y, s.y));
		setFrame(0);
	};
	virtual void setFrame(size_t frame) {
		setTextureRect(sf::IntRect(spriteWidth * frame, 0, spriteWidth, spriteWidth));
	}
	virtual bool update() { return true; };
	virtual void draw(sf::RenderWindow& win) {
		win.draw(*this);
//		drawPoly(win, poly);
	};

protected:
	virtual const Poly& getCollisionModel() {
		static const Poly model;
		return model;
	}
	virtual void updateCollisionPoly() {
		const Poly& model = getCollisionModel();
		poly.resize(model.size());
		sf::Transform trans = getTransform();
		trans.translate(getOrigin());
		for (size_t i = 0; i < poly.size(); i++) poly[i] = trans * model[i];
	}
	size_t frameCount;
	size_t spriteWidth;
	Poly poly;
};

