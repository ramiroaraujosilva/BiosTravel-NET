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
    internal class PPaqueteViaje : IPPaqueteViaje
    {
        #region Singleton

        // Singleton
        private static PPaqueteViaje _Instancia = null;

        // Constructor por defecto
        private PPaqueteViaje() { }

        // GetInstancia
        public static PPaqueteViaje GetInstancia()
        {
            if (_Instancia == null)
                _Instancia = new PPaqueteViaje();

            return _Instancia;
        }

        #endregion

        #region Operaciones

        public void Alta(PaquetesViajes unPaqueteViaje, Empleados pLogueo)
        {
            SqlConnection _cnn = new SqlConnection(Conexion.Cnn(pLogueo));

            SqlCommand _comando = new SqlCommand("AltaPaquetesViajes", _cnn);
            _comando.CommandType = CommandType.StoredProcedure;
            _comando.Parameters.AddWithValue("@titulo", unPaqueteViaje.Titulo);
            _comando.Parameters.AddWithValue("@descripcion", unPaqueteViaje.Descripcion);
            _comando.Parameters.AddWithValue("@cantidadDiasP", unPaqueteViaje.CantidadDiasP);
            _comando.Parameters.AddWithValue("@precioIndividual", unPaqueteViaje.PrecioIndividual);
            _comando.Parameters.AddWithValue("@precioDosP", unPaqueteViaje.PrecioDosP);
            _comando.Parameters.AddWithValue("@precioTresP", unPaqueteViaje.PrecioTresP);
            _comando.Parameters.AddWithValue("@empleadoU", unPaqueteViaje.Empleado.Usuario);
            _comando.Parameters.AddWithValue("@vueloIC", unPaqueteViaje.VueloIda.Codigo);
            _comando.Parameters.AddWithValue("@vueloVC", unPaqueteViaje.VueloVuelta.Codigo);
            _comando.Parameters.AddWithValue("@estadoPVC", unPaqueteViaje.Estado.Codigo);

            SqlParameter _retorno = new SqlParameter("@Retorno", SqlDbType.Int);
            _retorno.Direction = ParameterDirection.ReturnValue;
            _comando.Parameters.Add(_retorno);

            SqlTransaction _miTRN = null;

            try
            {
                _cnn.Open();

                _miTRN = _cnn.BeginTransaction();

                _comando.Transaction = _miTRN;
                _comando.ExecuteNonQuery();
                unPaqueteViaje.Codigo = Convert.ToInt32(_retorno.Value);

                int _codRet = Convert.ToInt32(_retorno.Value);
                if (_codRet == -1)
                    throw new Exception("Ha dado un error con el Usuario, no se encuentra en la base de datos");
                if (_codRet == -2)
                    throw new Exception("No existe el Vuelo de ida");
                if (_codRet == -3)
                    throw new Exception("No existe el Vuelo de vuelta");
                if (_codRet == -4)
                    throw new Exception("No existe el Estado");
                if (_codRet == -5)
                    throw new Exception("No se ha podido dar el alta! Ha ocurrido un error con los datos ingresados");

                // genero alta de Incluyen
                foreach (Incluyen unIncluyen in unPaqueteViaje.IncluyenHospedajes)
                {
                    PIncluyen.AltaIncluyen(unIncluyen, unPaqueteViaje.Codigo, _miTRN);
                }

                _miTRN.Commit();
            }
            catch (Exception ex)
            {
                _miTRN.Rollback();
                throw new Exception(ex.Message);
            }
            finally
            {
                _cnn.Close();
            }
        }        

        public PaquetesViajes Buscar(string pCodigo, Empleados pLogueo)
        {
            SqlConnection _cnn = new SqlConnection(Conexion.Cnn(pLogueo));
            PaquetesViajes unPaqueteViaje = null;

            SqlCommand _comando = new SqlCommand("BuscarPaqueteViaje", _cnn);
            _comando.CommandType = CommandType.StoredProcedure;
            _comando.Parameters.AddWithValue("@codigo", pCodigo);

            try
            {
                _cnn.Open();
                SqlDataReader _lector = _comando.ExecuteReader();
                if (_lector.HasRows)
                {
                    _lector.Read();
                    int codigo = Convert.ToInt32(_lector["codigo"]);
                    string titulo = (string)_lector["titulo"];
                    string descripcion = (string)_lector["descripcion"];
                    int cantidadDiasP = (int)_lector["cantidadDiasP"];
                    double precioIndividual = Convert.ToDouble(_lector["precioIndividual"]);
                    double precioDosP = Convert.ToDouble(_lector["precioDosP"]);
                    double precioTresP = Convert.ToDouble(_lector["precioTresP"]);
                    Empleados Emp = PEmpleado.GetInstancia().Buscar((string)_lector["empleadoU"], pLogueo);
                    Vuelos VueloIda = PVuelo.GetInstancia().BuscarTodos((string)_lector["vueloIC"], pLogueo);
                    Vuelos VueloVuelta = PVuelo.GetInstancia().BuscarTodos((string)_lector["vueloVC"], pLogueo);
                    Estados Estado = PEstado.GetInstancia().BuscarTodos((string)_lector["estadoPVC"], pLogueo);
                    List<Incluyen> Incluyen = PIncluyen.ListarIncluyenDePV(codigo, pLogueo);

                    unPaqueteViaje = new PaquetesViajes(titulo, descripcion, cantidadDiasP, precioIndividual, precioDosP, precioTresP,
                        Emp, VueloIda, VueloVuelta, Estado, Incluyen);
                    unPaqueteViaje.Codigo = codigo;
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
            return unPaqueteViaje;
        }
        public List<PaquetesViajes> Listar(Empleados pLogueo)
        {
            SqlConnection _cnn = new SqlConnection(Conexion.Cnn(pLogueo));
            PaquetesViajes unPaqueteViaje = null;
            List<PaquetesViajes> listaPaqueteViaje = new List<PaquetesViajes>();

            SqlCommand _comando = new SqlCommand("ListarPaquetesViajes", _cnn);
            _comando.CommandType = CommandType.StoredProcedure;

            try
            {
                _cnn.Open();

                SqlDataReader _lector = _comando.ExecuteReader();
                if (_lector.HasRows)
                {
                    while (_lector.Read())
                    {
                        int codigo = Convert.ToInt32(_lector["codigo"]);
                        string titulo = (string)_lector["titulo"];
                        string descripcion = (string)_lector["descripcion"];
                        int cantidadDiasP = (int)_lector["cantidadDiasP"];
                        double precioIndividual = Convert.ToDouble(_lector["precioIndividual"]);
                        double precioDosP = Convert.ToDouble(_lector["precioDosP"]);
                        double precioTresP = Convert.ToDouble(_lector["precioTresP"]);
                        Empleados Emp = PEmpleado.GetInstancia().Buscar((string)_lector["empleadoU"], pLogueo);
                        Vuelos VueloIda = PVuelo.GetInstancia().BuscarTodos((string)_lector["vueloIC"], pLogueo);
                        Vuelos VueloVuelta = PVuelo.GetInstancia().BuscarTodos((string)_lector["vueloVC"], pLogueo);
                        Estados Estado = PEstado.GetInstancia().BuscarTodos((string)_lector["estadoPVC"], pLogueo);
                        List<Incluyen> Incluyen = PIncluyen.ListarIncluyenDePV(codigo, pLogueo);

                        unPaqueteViaje = new PaquetesViajes(titulo, descripcion, cantidadDiasP, precioIndividual, precioDosP, precioTresP, 
                            Emp, VueloIda, VueloVuelta, Estado, Incluyen);
                        unPaqueteViaje.Codigo = codigo;
                        
                        listaPaqueteViaje.Add(unPaqueteViaje);
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
            return listaPaqueteViaje;
        }

        public List<PaquetesViajes> ListarPaquetesViajesPorHospedaje(Hospedajes pHospedaje, Empleados pLogueo)
        {
            SqlConnection _cnn = new SqlConnection(Conexion.Cnn(pLogueo));
            PaquetesViajes unPaqueteViaje = null;
            List<PaquetesViajes> listaPaqueteViaje = new List<PaquetesViajes>();

            SqlCommand _comando = new SqlCommand("ListarPaquetesViajesXHospedajes", _cnn);
            _comando.CommandType = CommandType.StoredProcedure;
            _comando.Parameters.AddWithValue("@codigoH", pHospedaje.CodigoInterno);

            try
            {
                _cnn.Open();

                SqlDataReader _lector = _comando.ExecuteReader();
                if (_lector.HasRows)
                {
                    while (_lector.Read())
                    {
                        int codigo = Convert.ToInt32(_lector["codigo"]);
                        string titulo = (string)_lector["titulo"];
                        string descripcion = (string)_lector["descripcion"];
                        int cantidadDiasP = (int)_lector["cantidadDiasP"];
                        double precioIndividual = Convert.ToDouble(_lector["precioIndividual"]);
                        double precioDosP = Convert.ToDouble(_lector["precioDosP"]);
                        double precioTresP = Convert.ToDouble(_lector["precioTresP"]);
                        Empleados Emp = PEmpleado.GetInstancia().Buscar((string)_lector["empleadoU"], pLogueo);
                        Vuelos VueloIda = PVuelo.GetInstancia().BuscarTodos((string)_lector["vueloIC"], pLogueo);
                        Vuelos VueloVuelta = PVuelo.GetInstancia().BuscarTodos((string)_lector["vueloVC"], pLogueo);
                        Estados Estado = PEstado.GetInstancia().BuscarTodos((string)_lector["estadoPVC"], pLogueo);
                        List<Incluyen> Incluyen = PIncluyen.ListarIncluyenDePV(codigo, pLogueo);

                        unPaqueteViaje = new PaquetesViajes(titulo, descripcion, cantidadDiasP, precioIndividual, precioDosP, precioTresP,
                            Emp, VueloIda, VueloVuelta, Estado, Incluyen);
                        unPaqueteViaje.Codigo = codigo;

                        listaPaqueteViaje.Add(unPaqueteViaje);
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
            return listaPaqueteViaje;
        }

        #endregion
    }
}
