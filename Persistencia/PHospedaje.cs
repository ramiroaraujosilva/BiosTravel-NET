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
    internal class PHospedaje : IPHospedaje
    {
        #region Singleton

        // Singleton
        private static PHospedaje _Instancia = null;

        // Constructor por defecto
        private PHospedaje() { }

        // GetInstancia
        public static PHospedaje GetInstancia()
        {
            if (_Instancia == null)
                _Instancia = new PHospedaje();

            return _Instancia;
        }

        #endregion

        #region Operaciones

        public void Alta(Hospedajes unHospedaje, Empleados pLogueo)
        {
            SqlConnection _cnn = new SqlConnection(Conexion.Cnn(pLogueo));

            SqlCommand _comando = new SqlCommand("AltaHospedaje", _cnn);
            _comando.CommandType = CommandType.StoredProcedure;
            _comando.Parameters.AddWithValue("@codigoInterno", unHospedaje.CodigoInterno);
            _comando.Parameters.AddWithValue("@nombre", unHospedaje.Nombre);
            _comando.Parameters.AddWithValue("@calle", unHospedaje.Calle);
            _comando.Parameters.AddWithValue("@localidad", unHospedaje.Localidad);
            _comando.Parameters.AddWithValue("@precioH", unHospedaje.PrecioH);
            _comando.Parameters.AddWithValue("@tipoH", unHospedaje.TipoH);
            _comando.Parameters.AddWithValue("@estadoCodigo", unHospedaje.Estado.Codigo);

            SqlParameter _retorno = new SqlParameter("@Retorno", SqlDbType.Int);
            _retorno.Direction = ParameterDirection.ReturnValue;
            _comando.Parameters.Add(_retorno);

            try
            {
                _cnn.Open();

                _comando.ExecuteNonQuery();

                int _codRet = Convert.ToInt32(_retorno.Value);
                if (_codRet == -1)
                    throw new Exception("Ya existe un Hospedaje con ese Código");
                if (_codRet == -2)
                    throw new Exception("No existe el Estado");
                if (_codRet == -4)
                    throw new Exception("No se ha podido dar el alta!");
                if (_codRet == -5)
                    throw new Exception("No se ha podido dar el alta! Ha ocurrido un error con los datos ingresados");
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

        public void Eliminar(Hospedajes unHospedaje, Empleados pLogueo)
        {
            SqlConnection _cnn = new SqlConnection(Conexion.Cnn(pLogueo));

            SqlCommand _comando = new SqlCommand("BajaHospedaje", _cnn);
            _comando.CommandType = CommandType.StoredProcedure;
            _comando.Parameters.AddWithValue("@codigo", unHospedaje.CodigoInterno);

            SqlParameter _retorno = new SqlParameter("@Retorno", SqlDbType.Int);
            _retorno.Direction = ParameterDirection.ReturnValue;
            _comando.Parameters.Add(_retorno);

            try
            {
                _cnn.Open();

                _comando.ExecuteNonQuery();

                int _codRet = Convert.ToInt32(_retorno.Value);
                if (_codRet == -1)
                    throw new Exception("No existe un Hospedaje con ese Código");
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

        public void Modificar(Hospedajes unHospedaje, Empleados pLogueo)
        {
            SqlConnection _cnn = new SqlConnection(Conexion.Cnn(pLogueo));

            SqlCommand _comando = new SqlCommand("ModificarHospedaje", _cnn);
            _comando.CommandType = CommandType.StoredProcedure;
            _comando.Parameters.AddWithValue("@codigoInterno", unHospedaje.CodigoInterno);
            _comando.Parameters.AddWithValue("@nombre", unHospedaje.Nombre);
            _comando.Parameters.AddWithValue("@calle", unHospedaje.Calle);
            _comando.Parameters.AddWithValue("@localidad", unHospedaje.Localidad);
            _comando.Parameters.AddWithValue("@precioH", unHospedaje.PrecioH);
            _comando.Parameters.AddWithValue("@tipoH", unHospedaje.TipoH);
            _comando.Parameters.AddWithValue("@estadoCodigo", unHospedaje.Estado.Codigo);

            SqlParameter _retorno = new SqlParameter("@Retorno", SqlDbType.Int);
            _retorno.Direction = ParameterDirection.ReturnValue;
            _comando.Parameters.Add(_retorno);

            try
            {
                _cnn.Open();

                _comando.ExecuteNonQuery();

                int _codRet = Convert.ToInt32(_retorno.Value);
                if (_codRet == -1)
                    throw new Exception("No existe un Hospedaje con ese Código");
                if (_codRet == -2)
                    throw new Exception("No existe el Estado");
                if (_codRet == -3)
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

        public Hospedajes Buscar(string pCodigo, Empleados pLogueo)
        {
            SqlConnection _cnn = new SqlConnection(Conexion.Cnn(pLogueo));
            Hospedajes unHospedaje = null;

            SqlCommand _comando = new SqlCommand("BuscarHospedaje", _cnn);
            _comando.CommandType = CommandType.StoredProcedure;
            _comando.Parameters.AddWithValue("@codigo", pCodigo);

            try
            {
                _cnn.Open();

                SqlDataReader _lector = _comando.ExecuteReader();
                if (_lector.HasRows)
                {
                    _lector.Read();
                    unHospedaje = new Hospedajes((string)_lector["codigoInterno"], (string)_lector["nombre"], (string)_lector["calle"], (string)_lector["localidad"],
                        Convert.ToDouble(_lector["precioH"]), (string)_lector["tipoH"], PEstado.GetInstancia().BuscarTodos((string)_lector["estadoCodigo"], pLogueo));
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
            return unHospedaje;
        }
        
        public List<Hospedajes> Listar(Empleados pLogueo)
        {
            SqlConnection _cnn = new SqlConnection(Conexion.Cnn(pLogueo));
            Hospedajes unHospedaje = null;
            List<Hospedajes> listaHospedaje = new List<Hospedajes>();

            SqlCommand _comando = new SqlCommand("ListarHospedajes", _cnn);
            _comando.CommandType = CommandType.StoredProcedure;

            try
            {
                _cnn.Open();

                SqlDataReader _lector = _comando.ExecuteReader();
                if (_lector.HasRows)
                {
                    while (_lector.Read())
                    {
                        unHospedaje = new Hospedajes((string)_lector["codigoInterno"], (string)_lector["nombre"], (string)_lector["calle"], (string)_lector["localidad"],
                           Convert.ToDouble(_lector["precioH"]), (string)_lector["tipoH"], PEstado.GetInstancia().BuscarTodos((string)_lector["estadoCodigo"], pLogueo));
                        listaHospedaje.Add(unHospedaje);
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
            return listaHospedaje;
        }

        internal Hospedajes BuscarTodos(string pCodigo, Empleados pLogueo)
        {
            SqlConnection _cnn = new SqlConnection(Conexion.Cnn(pLogueo));
            Hospedajes unHospedaje = null;

            SqlCommand _comando = new SqlCommand("BuscarTodosHospedajes", _cnn);
            _comando.CommandType = CommandType.StoredProcedure;
            _comando.Parameters.AddWithValue("@codigo", pCodigo);

            try
            {
                _cnn.Open();

                SqlDataReader _lector = _comando.ExecuteReader();
                if (_lector.HasRows)
                {
                    _lector.Read();
                    unHospedaje = new Hospedajes((string)_lector["codigoInterno"], (string)_lector["nombre"], (string)_lector["calle"], (string)_lector["localidad"],
                        Convert.ToDouble(_lector["precioH"]), (string)_lector["tipoH"], PEstado.GetInstancia().BuscarTodos((string)_lector["estadoCodigo"], pLogueo));
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
            return unHospedaje;
        }

        #endregion
    }
}
