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
    internal class PEmpleado : IPEmpleado
    {
        #region Singleton

        // Singleton
        private static PEmpleado _Instancia = null;

        // Constructor por defecto
        private PEmpleado() { }

        // GetInstancia
        public static PEmpleado GetInstancia()
        {
            if (_Instancia == null)
                _Instancia = new PEmpleado();

            return _Instancia;
        }
        #endregion

        #region Operaciones

        public void NuevoUsuario(Empleados unEmpleado, Empleados pLogueo)
        {
            SqlConnection _cnn = new SqlConnection(Conexion.Cnn(pLogueo));

            SqlCommand _comando = new SqlCommand("NuevoUsuario", _cnn);

            _comando.CommandType = CommandType.StoredProcedure;
            _comando.Parameters.AddWithValue("@usuario", unEmpleado.Usuario);
            _comando.Parameters.AddWithValue("@passUsu", unEmpleado.PassUsu);
            _comando.Parameters.AddWithValue("@nomCompleto", unEmpleado.NombreCompleto);

            SqlParameter _retorno = new SqlParameter("@Retorno", SqlDbType.Int);
            _retorno.Direction = ParameterDirection.ReturnValue;
            _comando.Parameters.Add(_retorno);            

            try
            {
                _cnn.Open();              
              
                _comando.ExecuteNonQuery();

                int _codRet = Convert.ToInt32(_retorno.Value);
                if (_codRet == -1)
                    throw new Exception("Ya existe un Empleado con ese Usuario");
                if (_codRet == -2)
                    throw new Exception("No se ha podido dar el alta! Ha ocurrido un error con los valores ingresados");
                if (_codRet == -3)
                    throw new Exception("No se ha podido dar el alta! Se generó un problema al intentar crear el usuario LOGIN del servidor");
                if (_codRet == -4)
                    throw new Exception("No se ha podido dar el alta! Se generó un problema al intentar crear el usuario de la base de datos");
                if (_codRet == -5)
                    throw new Exception("Ha ocurrido un error al querer asignarle el ROL de EXECUTOR en la base de datos");
                if (_codRet == -6)
                    throw new Exception("Ha ocurrido un error al querer asignarle el ROL de SEGURIDAD en la base de datos");
                if (_codRet == -7)
                    throw new Exception("Ha ocurrido un error al querer asignarle el ROL de LOGINS en el servidor");
                
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

        public void Modificar(Empleados unEmpleado, Empleados pLogueo)
        {
            SqlConnection _cnn = new SqlConnection(Conexion.Cnn(pLogueo));

            SqlCommand _comando = new SqlCommand("ModificarEmpleado", _cnn);

            _comando.CommandType = CommandType.StoredProcedure;
            _comando.Parameters.AddWithValue("@usuario", unEmpleado.Usuario);
            _comando.Parameters.AddWithValue("@passUsu", unEmpleado.PassUsu);
            _comando.Parameters.AddWithValue("@nombreCompleto", unEmpleado.NombreCompleto);

            SqlParameter _retorno = new SqlParameter("@Retorno", SqlDbType.Int);
            _retorno.Direction = ParameterDirection.ReturnValue;
            _comando.Parameters.Add(_retorno);

            try
            {
                _cnn.Open();

                _comando.ExecuteNonQuery();

                int _codRet = Convert.ToInt32(_retorno.Value);
                if (_codRet == -1)
                    throw new Exception("No existe un Empleado con ese Usuario");
                if (_codRet == -2)
                    throw new Exception("No se ha podido modificar, existe un problema con los valores ingresados");
                if (_codRet == -3)
                    throw new Exception("No se ha podido modificar, se generó un problema al querer modificar el LOGIN del servidor");
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

        public Empleados Logueo(string pUsuario, string pPassUsu)
        {
            SqlConnection _cnn = new SqlConnection(Conexion.Cnn());
            Empleados _unEmpleado = null;

            SqlCommand _comando = new SqlCommand("Logueo", _cnn);

            _comando.CommandType = CommandType.StoredProcedure;
            _comando.Parameters.AddWithValue("@usu", pUsuario);
            _comando.Parameters.AddWithValue("@pass", pPassUsu);

            try
            {
                _cnn.Open();

                SqlDataReader _lector = _comando.ExecuteReader();
                if (_lector.HasRows)
                {
                    _lector.Read();
                    _unEmpleado = new Empleados((string)_lector["usuario"], (string)_lector["passUsu"], (string)_lector["nombreCompleto"]);
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
            return _unEmpleado;
        }

        public Empleados Buscar(string pUsuario, Empleados pLogueo)
        {
            SqlConnection _cnn = new SqlConnection(Conexion.Cnn(pLogueo));
            Empleados _unEmpleado = null;

            SqlCommand _comando = new SqlCommand("BuscarEmpleado", _cnn);

            _comando.CommandType = CommandType.StoredProcedure;
            _comando.Parameters.AddWithValue("@usuario", pUsuario);

            try
            {
                _cnn.Open();

                SqlDataReader _lector = _comando.ExecuteReader();
                if (_lector.HasRows)
                {
                    _lector.Read();
                    _unEmpleado = new Empleados((string)_lector["usuario"], (string)_lector["passUsu"], (string)_lector["nombreCompleto"]);
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
            return _unEmpleado;
        }

        public List<Empleados> Listar(Empleados pLogueo)
        {
            SqlConnection _cnn = new SqlConnection(Conexion.Cnn(pLogueo));
            Empleados _unEmpleado = null;
            List<Empleados> _listaEmpleados = new List<Empleados>();

            SqlCommand _comando = new SqlCommand("ListarEmpleados", _cnn);

            try
            {
                _cnn.Open();

                SqlDataReader _lector = _comando.ExecuteReader();
                if (_lector.HasRows)
                {
                    while (_lector.Read())
                    {
                        _unEmpleado = new Empleados((string)_lector["usuario"], (string)_lector["passUsu"], (string)_lector["nombreCompleto"]);
                        _listaEmpleados.Add(_unEmpleado);
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
            return _listaEmpleados;
        }

        #endregion
    }
}
