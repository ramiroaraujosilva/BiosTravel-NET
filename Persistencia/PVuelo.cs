using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using Persistencia.Interfaces;
using Entidades_Compartidas;
using System.Data.SqlClient;
using System.Data;

namespace Persistencia
{
    internal class PVuelo : IPVuelo
    {
        #region Singleton

        // Singleton
        private static PVuelo _Instancia = null;

        // Constructor por defecto
        private PVuelo() { }

        // GetInstancia
        public static PVuelo GetInstancia()
        {
            if (_Instancia == null)
                _Instancia = new PVuelo();

            return _Instancia;
        }

        #endregion

        #region Operaciones

        public void Alta(Vuelos unVuelo, Empleados pLogueo)
        {
            SqlConnection _cnn = new SqlConnection(Conexion.Cnn(pLogueo));

            SqlCommand _comando = new SqlCommand("AltaVuelo", _cnn);
            _comando.CommandType = CommandType.StoredProcedure;
            _comando.Parameters.AddWithValue("@codigo", unVuelo.Codigo);
            _comando.Parameters.AddWithValue("@fechaHoraP", unVuelo.FechaHoraP);
            _comando.Parameters.AddWithValue("@fechaHoraL", unVuelo.FechaHoraL);
            _comando.Parameters.AddWithValue("@precioV", unVuelo.PrecioV);
            _comando.Parameters.AddWithValue("@estadoPartidaC", unVuelo.EstadoPartida.Codigo);
            _comando.Parameters.AddWithValue("@estadoArriboC", unVuelo.EstadoArribo.Codigo);

            SqlParameter _retorno = new SqlParameter("@Retorno", SqlDbType.Int);
            _retorno.Direction = ParameterDirection.ReturnValue;
            _comando.Parameters.Add(_retorno);

            try
            {
                _cnn.Open();

                _comando.ExecuteNonQuery();

                int _codRet = Convert.ToInt32(_retorno.Value);
                if (_codRet == -1)
                    throw new Exception("Ya existe un Vuelo con ese Código");
                if (_codRet == -2)
                    throw new Exception("No existe el Estado de partida");
                if (_codRet == -3)
                    throw new Exception("No existe el Estado de arribo");
                if (_codRet == -4)
                    throw new Exception("No se ha podido dar el alta!");
                if (_codRet == -5)
                    throw new Exception("No se ha podido dar el alta! Los datos ingresados no son válidos");
            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
            finally
            {
                _cnn.Close();
            }
        }

        public void Eliminar(Vuelos unVuelo, Empleados pLogueo)
        {
            SqlConnection _cnn = new SqlConnection(Conexion.Cnn(pLogueo));

            SqlCommand _comando = new SqlCommand("BajaVuelo", _cnn);
            _comando.CommandType = CommandType.StoredProcedure;
            _comando.Parameters.AddWithValue("@codigo", unVuelo.Codigo);

            SqlParameter _retorno = new SqlParameter("@Retorno", SqlDbType.Int);
            _retorno.Direction = ParameterDirection.ReturnValue;
            _comando.Parameters.Add(_retorno);

            try
            {
                _cnn.Open();

                _comando.ExecuteNonQuery();

                int _codRet = Convert.ToInt32(_retorno.Value);
                if (_codRet == -1)
                    throw new Exception("No existe un Vuelo con ese Código");
                if (_codRet == -2)
                    throw new Exception("Ha ocurrido un error y no se ha podido dar la baja");
            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
            finally
            {
                _cnn.Close();
            }
        }

        public void Modificar(Vuelos unVuelo, Empleados pLogueo)
        {
            SqlConnection _cnn = new SqlConnection(Conexion.Cnn(pLogueo));

            SqlCommand _comando = new SqlCommand("ModificarVuelo", _cnn);
            _comando.CommandType = CommandType.StoredProcedure;
            _comando.Parameters.AddWithValue("@codigo", unVuelo.Codigo);
            _comando.Parameters.AddWithValue("@fechaHoraP", unVuelo.FechaHoraP);
            _comando.Parameters.AddWithValue("@fechaHoraL", unVuelo.FechaHoraL);
            _comando.Parameters.AddWithValue("@precioV", unVuelo.PrecioV);
            _comando.Parameters.AddWithValue("@estadoPartidaC", unVuelo.EstadoPartida.Codigo);
            _comando.Parameters.AddWithValue("@estadoArriboC", unVuelo.EstadoArribo.Codigo);

            SqlParameter _retorno = new SqlParameter("@Retorno", SqlDbType.Int);
            _retorno.Direction = ParameterDirection.ReturnValue;
            _comando.Parameters.Add(_retorno);

            try
            {
                _cnn.Open();

                _comando.ExecuteNonQuery();

                int _codRet = Convert.ToInt32(_retorno.Value);
                if (_codRet == -1)
                    throw new Exception("No existe un Vuelo con ese Código");
                if (_codRet == -2)
                    throw new Exception("No existe el Estado de partida");
                if (_codRet == -3)
                    throw new Exception("No existe el Estado de arribo");
                if (_codRet == -4)
                    throw new Exception("No se ha podido hacer la modificación! Ha ocurrido un error con los nuevos datos ingresados");
            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
            finally
            {
                _cnn.Close();
            }
        }

        public Vuelos Buscar(string pCodigo, Empleados pLogueo)
        {
            SqlConnection _cnn = new SqlConnection(Conexion.Cnn(pLogueo));
            Vuelos unVuelo = null;

            SqlCommand _comando = new SqlCommand("BuscarVuelos", _cnn);
            _comando.CommandType = CommandType.StoredProcedure;
            _comando.Parameters.AddWithValue("@codigo", pCodigo);

            try
            {
                _cnn.Open();

                SqlDataReader _lector = _comando.ExecuteReader();
                if (_lector.HasRows)
                {
                    _lector.Read();
                    unVuelo = new Vuelos((string)_lector["codigo"], (DateTime)_lector["fechaHoraP"], (DateTime)_lector["fechaHoraL"], Convert.ToDouble(_lector["precioV"]),
                        PEstado.GetInstancia().BuscarTodos((string)_lector["estadoPartidaC"], pLogueo), PEstado.GetInstancia().BuscarTodos((string)_lector["estadoArriboC"], pLogueo));
                }
            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
            finally
            {
                _cnn.Close();
            }
            return unVuelo;
        }

        public List<Vuelos> Listar(Empleados pLogueo)
        {
            SqlConnection _cnn = new SqlConnection(Conexion.Cnn(pLogueo));
            Vuelos unVuelo = null;
            List<Vuelos> _listaVuelos = new List<Vuelos>();

            SqlCommand _comando = new SqlCommand("ListarVuelos", _cnn);
            _comando.CommandType = CommandType.StoredProcedure;            

            try
            {
                _cnn.Open();

                SqlDataReader _lector = _comando.ExecuteReader();
                if (_lector.HasRows)
                {
                    while(_lector.Read())
                    {
                        unVuelo = new Vuelos((string)_lector["codigo"], (DateTime)_lector["fechaHoraP"], (DateTime)_lector["fechaHoraL"], Convert.ToDouble(_lector["precioV"]),
                          PEstado.GetInstancia().BuscarTodos((string)_lector["estadoPartidaC"], pLogueo), PEstado.GetInstancia().BuscarTodos((string)_lector["estadoArriboC"], pLogueo));
                        _listaVuelos.Add(unVuelo);
                    }                   
                }
            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
            finally
            {
                _cnn.Close();
            }
            return _listaVuelos;
        }

        internal Vuelos BuscarTodos(string pCodigo, Empleados pLogueo)
        {
            SqlConnection _cnn = new SqlConnection(Conexion.Cnn(pLogueo));
            Vuelos unVuelo = null;

            SqlCommand _comando = new SqlCommand("BuscarTodosVuelos", _cnn);
            _comando.CommandType = CommandType.StoredProcedure;
            _comando.Parameters.AddWithValue("@codigo", pCodigo);

            try
            {
                _cnn.Open();

                SqlDataReader _lector = _comando.ExecuteReader();
                if (_lector.HasRows)
                {
                    _lector.Read();
                    unVuelo = new Vuelos((string)_lector["codigo"], (DateTime)_lector["fechaHoraP"], (DateTime)_lector["fechaHoraL"], Convert.ToDouble(_lector["precioV"]),
                        PEstado.GetInstancia().BuscarTodos((string)_lector["estadoPartidaC"], pLogueo), PEstado.GetInstancia().BuscarTodos((string)_lector["estadoArriboC"], pLogueo));
                }
            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
            finally
            {
                _cnn.Close();
            }
            return unVuelo;
        }

        #endregion
    }
}
