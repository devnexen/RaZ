#pragma once

#ifndef RAZ_SHADERPROGRAM_HPP
#define RAZ_SHADERPROGRAM_HPP

#include <string>

#include "glew/include/GL/glew.h"
#include "RaZ/Math/Matrix.hpp"
#include "RaZ/Math/Vector.hpp"
#include "RaZ/Render/Shader.hpp"

namespace Raz {

class ShaderProgram {
public:
  ShaderProgram(VertexShaderPtr vertShader, FragmentShaderPtr fragShader);

  GLuint getIndex() const { return m_index; }

  void updateShaders() const;
  void use() const { glUseProgram(m_index); }
  GLint recoverUniformLocation(const std::string& uniformName) const { return glGetUniformLocation(m_index, uniformName.c_str()); }
  template <typename T> void sendUniform(GLint uniformIndex, T value) const;
  template <typename T, std::size_t Size> void sendUniform(GLint uniformIndex, const Vector<T, Size>& vec) const;
  template <typename T, std::size_t W, std::size_t H> void sendUniform(GLint uniformIndex, const Matrix<T, W, H>& mat) const;
  template <typename T> void sendUniform(const std::string& uniformName, T value) const {
    sendUniform(recoverUniformLocation(uniformName), value);
  }

private:
  void loadShaders() const;
  void compileShaders() const;
  void link() const;

  GLuint m_index;

  VertexShaderPtr m_vertShader;
  FragmentShaderPtr m_fragShader;
};

} // namespace Raz

#endif // RAZ_SHADERPROGRAM_HPP
