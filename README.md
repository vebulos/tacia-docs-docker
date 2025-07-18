# TaciaDocs - Docker Setup

This directory contains the Docker configuration for running the TaciaDocs platform. For comprehensive documentation, please refer to the main [Frontend README](../frontend/README.md).

## 🚀 Quick Start with Docker

### Prerequisites

- [Docker](https://www.docker.com/products/docker-desktop/) installed on your system
- Git to clone the repositories

### Setup Instructions

1. **Clone the required repositories**:
   ```bash
   # Frontend
   git clone https://github.com/vebulos/tacia-docs.git frontend
   
   # Backend (choose one or both)
   git clone https://github.com/vebulos/tacia-docs-backend-js.git backend-js  # Node.js backend (recommended for development)
   git clone https://github.com/vebulos/tacia-docs-backend-java.git backend-java # Java backend (recommended for production)
   
   # Docker setup
   git clone https://github.com/vebulos/tacia-docs-docker.git docker
   ```

2. **Prepare your content directory** with your markdown documentation files.

3. **Start the application** from the docker directory:
   ```bash
   cd docker
   ./start-app.sh [js|java] <path_to_content_directory>
   ```
   - Use `js` for Node.js backend or `java` for Java backend
   - Example: `./start-app.sh js /path/to/your/content`

4. **Access the application**:
   - Frontend: [http://localhost](http://localhost)
   - API: [http://localhost/api/](http://localhost/api/)

## 📚 Detailed Documentation

For complete documentation, including:
- Detailed setup instructions
- Configuration options
- Development setup
- Troubleshooting

Please visit the main [Frontend README](https://github.com/vebulos/tacia-docs).

## 🛑 Stopping the Application

To stop and clean up all containers:
```bash
./clean-docker.sh
```

## 🤝 Contributing

If you'd like to contribute to the Docker setup, please refer to the main project's contribution guidelines in the frontend repository.

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details.
