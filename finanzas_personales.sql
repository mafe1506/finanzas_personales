-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1:3306
-- Tiempo de generación: 30-11-2024 a las 00:23:17
-- Versión del servidor: 9.1.0
-- Versión de PHP: 8.3.14

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `finanzas_personales`
--

DELIMITER $$
--
-- Procedimientos
--
DROP PROCEDURE IF EXISTS `registrar_transaccion`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `registrar_transaccion` (IN `p_id_usuario` INT, IN `p_monto` DECIMAL(10,2), IN `p_tipo` VARCHAR(10), IN `p_categoria` INT, IN `p_fecha` DATE)   BEGIN
    INSERT INTO Transacciones (id_usuario, monto, tipo, categoria, fecha)
    VALUES (p_id_usuario, p_monto, p_tipo, p_categoria, p_fecha);
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `categorias`
--

DROP TABLE IF EXISTS `categorias`;
CREATE TABLE IF NOT EXISTS `categorias` (
  `id_categoria` int NOT NULL AUTO_INCREMENT,
  `nombre` varchar(50) COLLATE utf8mb4_general_ci NOT NULL,
  `descripcion` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `limite` decimal(10,2) DEFAULT '0.00',
  PRIMARY KEY (`id_categoria`)
) ENGINE=MyISAM AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `categorias`
--

INSERT INTO `categorias` (`id_categoria`, `nombre`, `descripcion`, `limite`) VALUES
(1, 'Alimentos', 'Gastos relacionados con alimentos', 500.00);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `metas_financieras`
--

DROP TABLE IF EXISTS `metas_financieras`;
CREATE TABLE IF NOT EXISTS `metas_financieras` (
  `id_meta` int NOT NULL AUTO_INCREMENT,
  `id_usuario` int NOT NULL,
  `descripcion` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `monto_objetivo` decimal(10,2) NOT NULL,
  `monto_actual` decimal(10,2) DEFAULT '0.00',
  `fecha_meta` date NOT NULL,
  PRIMARY KEY (`id_meta`),
  KEY `id_usuario` (`id_usuario`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `reportes`
--

DROP TABLE IF EXISTS `reportes`;
CREATE TABLE IF NOT EXISTS `reportes` (
  `id_reporte` int NOT NULL AUTO_INCREMENT,
  `id_usuario` int NOT NULL,
  `total_gastos` decimal(10,2) NOT NULL,
  `total_ingresos` decimal(10,2) NOT NULL,
  `fecha` date NOT NULL,
  PRIMARY KEY (`id_reporte`),
  KEY `id_usuario` (`id_usuario`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `transacciones`
--

DROP TABLE IF EXISTS `transacciones`;
CREATE TABLE IF NOT EXISTS `transacciones` (
  `id_transaccion` int NOT NULL AUTO_INCREMENT,
  `id_usuario` int NOT NULL,
  `monto` decimal(10,2) NOT NULL,
  `tipo` enum('ingreso','gasto') COLLATE utf8mb4_general_ci NOT NULL,
  `fecha` date NOT NULL,
  `categoria` int NOT NULL,
  PRIMARY KEY (`id_transaccion`),
  KEY `id_usuario` (`id_usuario`),
  KEY `categoria` (`categoria`)
) ENGINE=MyISAM AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `transacciones`
--

INSERT INTO `transacciones` (`id_transaccion`, `id_usuario`, `monto`, `tipo`, `fecha`, `categoria`) VALUES
(1, 1, 100.00, 'ingreso', '2024-11-29', 1),
(2, 1, 50.00, 'gasto', '2024-11-29', 1);

--
-- Disparadores `transacciones`
--
DROP TRIGGER IF EXISTS `actualizar_saldo`;
DELIMITER $$
CREATE TRIGGER `actualizar_saldo` AFTER INSERT ON `transacciones` FOR EACH ROW BEGIN
    UPDATE Usuarios
    SET saldo = saldo + 
        CASE 
            WHEN NEW.tipo = 'ingreso' THEN NEW.monto
            WHEN NEW.tipo = 'gasto' THEN -NEW.monto
        END
    WHERE id_usuario = NEW.id_usuario;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuarios`
--

DROP TABLE IF EXISTS `usuarios`;
CREATE TABLE IF NOT EXISTS `usuarios` (
  `id_usuario` int NOT NULL AUTO_INCREMENT,
  `nombre` varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  `email` varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  `contraseña` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `saldo` decimal(10,2) DEFAULT '0.00',
  PRIMARY KEY (`id_usuario`),
  UNIQUE KEY `email` (`email`)
) ENGINE=MyISAM AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `usuarios`
--

INSERT INTO `usuarios` (`id_usuario`, `nombre`, `email`, `contraseña`, `saldo`) VALUES
(1, 'Juan Pérez', 'juan.perez@example.com', '1234', 50.00);

DELIMITER $$
--
-- Eventos
--
DROP EVENT IF EXISTS `generar_reporte_mensual`$$
CREATE DEFINER=`root`@`localhost` EVENT `generar_reporte_mensual` ON SCHEDULE EVERY 1 MONTH STARTS '2024-11-29 19:04:44' ON COMPLETION NOT PRESERVE ENABLE DO BEGIN
    INSERT INTO Reportes (id_usuario, total_gastos, total_ingresos, fecha)
    SELECT id_usuario,
           SUM(CASE WHEN tipo = 'gasto' THEN monto ELSE 0 END) AS total_gastos,
           SUM(CASE WHEN tipo = 'ingreso' THEN monto ELSE 0 END) AS total_ingresos,
           CURDATE() AS fecha
    FROM Transacciones
    WHERE MONTH(fecha) = MONTH(CURDATE()) AND YEAR(fecha) = YEAR(CURDATE())
    GROUP BY id_usuario;
END$$

DELIMITER ;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
