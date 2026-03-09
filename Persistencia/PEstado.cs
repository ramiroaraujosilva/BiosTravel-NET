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
    internal class PEstado : IPEstado
    {
        #region Singleton

        // Singleton
        private static PEstado _Instancia = null;

        // Constructor por defecto
        private PEstado() { }

        // GetInstancia
        public static PEstado GetInstancia()
        {
            if (_Instancia == null)
                _Instancia = new PEstado();

            return _Instancia;
        }

        #endregion

        #region Operaciones

        public void Alta(Estados unEstado, Empleados pLogueo)
        {
            SqlConnection _cnn = new SqlConnection(Conexion.Cnn(pLogueo));

            SqlCommand _comando = new SqlCommand("AltaEstado", _cnn);
            _comando.CommandType = CommandType.StoredProcedure;
            _comando.Parameters.AddWithValue("@codigo", unEstado.Codigo);
            _comando.Parameters.AddWithValue("@nombre", unEstado.Nombre);
            _comando.Parameters.AddWithValue("@pais", unEstado.Pais);

            SqlParameter _retorno = new SqlParameter("@Retorno", SqlDbType.Int);
            _retorno.Direction = ParameterDirection.ReturnValue;
            _comando.Parameters.Add(_retorno);

            try
            {
                _cnn.Open();

                _comando.ExecuteNonQuery();

                int _codRet = Convert.ToInt32(_retorno.Value);
                if (_codRet == -1)
                    throw new Exception("Ya existe un Estado con ese Código");
                if (_codRet == -2)
                    throw new Exception("No se ha podido dar el alta!");
                if (_codRet == -3)
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

        public void Eliminar(Estados unEstado, Empleados pLogueo)
        {
            SqlConnection _cnn = new SqlConnection(Conexion.Cnn(pLogueo));

            SqlCommand _comando = new SqlCommand("BajaEstados", _cnn);
            _comando.CommandType = CommandType.StoredProcedure;
            _comando.Parameters.AddWithValue("@codigo", unEstado.Codigo);

            SqlParameter _retorno = new SqlParameter("@Retorno", SqlDbType.Int);
            _retorno.Direction = ParameterDirection.ReturnValue;
            _comando.Parameters.Add(_retorno);

            try
            {
                _cnn.Open();

                _comando.ExecuteNonQuery();

                int _codRet = Convert.ToInt32(_retorno.Value);
                if (_codRet == -1)
                    throw new Exception("No existe un Estado con ese Código");
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

        public void Modificar(Estados unEstado, Empleados pLogueo)
        {
            SqlConnection _cnn = new SqlConnection(Conexion.Cnn(pLogueo));

            SqlCommand _comando = new SqlCommand("ModificarEstado", _cnn);
            _comando.CommandType = CommandType.StoredProcedure;
            _comando.Parameters.AddWithValue("@codigo", unEstado.Codigo);
            _comando.Parameters.AddWithValue("@nombre", unEstado.Nombre);
            _comando.Parameters.AddWithValue("@pais", unEstado.Pais);

            SqlParameter _retorno = new SqlParameter("@Retorno", SqlDbType.Int);
            _retorno.Direction = ParameterDirection.ReturnValue;
            _comando.Parameters.Add(_retorno);

            try
            {
                _cnn.Open();

                _comando.ExecuteNonQuery();

                int _codRet = Convert.ToInt32(_retorno.Value);
                if (_codRet == -1)
                    throw new Exception("No existe un Estado con ese Código");
                if (_codRet == -2)
                    throw new Exception("Ha ocurrido un error con los valores ingresados, y no se ha podido realizar la modificación");
            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message); ;
            }
            finally
            {
                _cnn.Close();
            }
        }

        public Estados Buscar(string pCodigo, Empleados pLogueo)
        {
            SqlConnection _cnn = new SqlConnection(Conexion.Cnn(pLogueo));
            Estados unEstado = null;

            SqlCommand _comando = new SqlCommand("BuscarEstados", _cnn);
            _comando.CommandType = CommandType.StoredProcedure;
            _comando.Parameters.AddWithValue("@codigo", pCodigo);

            try
            {
                _cnn.Open();

                SqlDataReader _lector = _comando.ExecuteReader();
                if (_lector.HasRows)
                {
                    _lector.Read();
                    unEstado = new Estados((string)_lector["codigo"], (string)_lector["nombre"], (string)_lector["pais"]);
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
            return unEstado;
        }

        public List<Estados> Listar(Empleados pLogueo)
        {
            SqlConnection _cnn = new SqlConnection(Conexion.Cnn(pLogueo));
            Estados unEstado = null;
            List<Estados> _listaEstados = new List<Estados>();

            SqlCommand _comando = new SqlCommand("ListarEstados", _cnn);

            try
            {
                _cnn.Open();

                SqlDataReader _lector = _comando.ExecuteReader();
                if (_lector.HasRows)
                {
                    while (_lector.Read())
                    {
                        unEstado = new Estados((string)_lector["codigo"], (string)_lector["nombre"], (string)_lector["pais"]);
                        _listaEstados.Add(unEstado);
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
            return _listaEstados;
        }

        internal Estados BuscarTodos(string pCodigo, Empleados pLogueo)
        {
            SqlConnection _cnn = new SqlConnection(Conexion.Cnn(pLogueo));
            Estados unEstado = null;            

            SqlCommand _comando = new SqlCommand("BuscarTodosEstados", _cnn);
            _comando.CommandType = CommandType.StoredProcedure;
            _comando.Parameters.AddWithValue("@codigo", pCodigo);

            try
            {
                _cnn.Open();

                SqlDataReader _lector = _comando.ExecuteReader();
                if (_lector.HasRows)
                {
                    _lector.Read();
                    unEstado = new Estados((string)_lector["codigo"], (string)_lector["nombre"], (string)_lector["pais"]);
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
            return unEstado;
        }

        #endregion
    }
}
