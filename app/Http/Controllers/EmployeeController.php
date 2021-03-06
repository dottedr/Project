<?php

namespace App\Http\Controllers;

use App\VerifyUser;
use Illuminate\Http\Request;

use Illuminate\Auth\Middleware\Authenticate;
use App\Http\Requests;
use App\User;
use App\Http\Resources\User as EmployeeResource;
use Illuminate\Support\Facades\Auth;
use App\Mail\VerifyMail;
use Illuminate\Support\Facades\Mail;

class EmployeeController extends Controller
{
    /**
     * Display a listing of the resource.
     *
     * @return \Illuminate\Http\Response
     */
    public function __construct()
    {
        $this->middleware('auth:admin');
    }


    /**
     * If the admin chose an employee from the list go to employees profile.
     *
     * @return \Illuminate\Http\Response
     */
    public function indexView($userid=null)
    { if($userid==null){
        return view('team', array("userid"=>$userid));}
    else{
        return view('employee',array("userid"=>$userid));
    }
    }

    public function index()
    {
        $isadmin = Auth::user()->isadmin;
        if($isadmin==1) {
            $employee = User::all();
            return Response()->json(array("status"=>true, "data"=>$employee));
        }
        else{
            return Response()->json(array("status"=>false));
        }

    }


    public function newView($userid=null){

        return view('newemployee');
    }

    /**
     * Store a newly created resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\Response
     */
    public function store(Request $request)
    {
        $employee = User::create([
            'isadmin' => $request->isadmin,
            'verified'=> $request->verified,
            'name' => $request->name,
            'email'=>$request->email,
            'password'=>$request->password,
            'holiday_allowance'=>$request->holiday_allowance,
            'role'=>$request->role,
            'created_at' => $request->timestamp,
            'updated_at' => $request->timestamp]);

        $verifyUser = VerifyUser::create([
            'user_id' => $employee->id,
            'token' => str_random(40)]);

        Mail::to($employee->email)->send(new VerifyMail($employee));

        return Response()->json(array("status"=>true, "data"=>$employee));
    }


    /**
     * Display the specified resource.
     *
     * @param  int  $id
     * @return \Illuminate\Http\Response
     */
    public function show($id)
    {

        $employee=User::findOrFail($id);
        return Response()->json(array("status"=>true, "data"=>$employee));
    }

    /**
     * Update the specified resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  int  $id
     * @return \Illuminate\Http\Response
     */
    public function update(Request $request, $id)
    {
        //
    }

}
